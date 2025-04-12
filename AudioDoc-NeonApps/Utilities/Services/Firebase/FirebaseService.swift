import Firebase
import FirebaseStorage
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    private let recordingsCollection = "recordings"
    private let audioStorageFolder = "audios"
    private let imageStorageFolder = "images"
    
    init() {
        print("FirebaseService initialized")
//        print("Storage bucket: \(Storage.storage().app.options.storageBucket ?? "Not set")")
        
        // Storage klasörlerini oluştur
        self.createStorageFolders()
    }
    
    private func createStorageFolders() {
        // Klasörler zaten varsa bir şey yapmaz, yoksa oluşturulur
        print("Ensuring storage folders exist...")
    }
    
    // MARK: - Audio Upload
    /// Upload audio file to Firebase Storage
    func uploadAudio(from url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let fileName = "\(UUID().uuidString)_\(url.lastPathComponent)"
        let audioRef = storage.child("\(audioStorageFolder)/\(fileName)")
        
        // Dosyanın var olduğundan emin ol
        guard FileManager.default.fileExists(atPath: url.path) else {
            let error = NSError(domain: "FirebaseService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Audio file does not exist at path: \(url.path)"])
            completion(.failure(error))
            return
        }
        
        print("Starting upload for file at path: \(url.path)")
        print("Uploading to Firebase Storage path: \(audioStorageFolder)/\(fileName)")
        print("File reference: \(audioRef)")
        
        // Dosya boyutu kontrol
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? NSNumber {
                print("Uploading file size: \(fileSize.intValue) bytes")
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        
        // Start uploading task with metadata
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"
        
        audioRef.putFile(from: url, metadata: metadata) { metadata, error in
            if let error = error {
                print("Firebase Storage upload error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Get download URL
            audioRef.downloadURL { url, error in
                if let error = error {
                    print("Firebase Storage download URL error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    let error = NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    print("Download URL is nil")
                    completion(.failure(error))
                    return
                }
                
                print("Successfully uploaded file. Download URL: \(downloadURL)")
                completion(.success(downloadURL))
            }
        }
    }
    
    // MARK: - Image Upload
    /// Upload image to Firebase Storage
    func uploadImage(_ image: UIImage?, completion: @escaping (Result<String, Error>) -> Void) {
        guard let image = image, let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let imageRef = storage.child("\(imageStorageFolder)/\(fileName)")
        
        // Start uploading task
        _ = imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Get download URL
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    completion(.failure(NSError(domain: "FirebaseService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                completion(.success(downloadURL))
            }
        }
    }
    
    // MARK: - Save Recording
    /// Firestore'a kayıt
    func saveRecording(_ recording: Recording, completion: @escaping (Result<String, Error>) -> Void) {
        let recordingDict = recording.toDictionary()
        
        // Firestore'a ekle
        db.collection(recordingsCollection).document(recording.id).setData(recordingDict) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(recording.id))
        }
    }
    
    // MARK: - Fetch Recordings
    /// Tüm kayıtları getir
    func fetchAllRecordings(completion: @escaping (Result<[Recording], Error>) -> Void) {
        db.collection(recordingsCollection)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let recordings = documents.compactMap { Recording(document: $0) }
                completion(.success(recordings))
            }
    }
    
    // MARK: - Delete Recording
    /// Kayıt silme
    func deleteRecording(_ recording: Recording, completion: @escaping (Result<Void, Error>) -> Void) {
        // Önce kayıt bilgilerini al
        db.collection(recordingsCollection).document(recording.id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, let data = snapshot.data() else {
                completion(.failure(NSError(domain: "FirebaseService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Recording not found"])))
                return
            }
            
            // Kayıt silme işlemi
            self.db.collection(self.recordingsCollection).document(recording.id).delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // İlişkili dosyaları silme işlemi
                if let audioURL = data["audioURL"] as? String {
                    let audioRef = Storage.storage().reference(forURL: audioURL)
                    audioRef.delete { error in
                        if let error = error {
                            print("Error deleting audio file: \(error.localizedDescription)")
                        }
                    }
                }
                
                if let imageURL = data["imageURL"] as? String {
                    let imageRef = Storage.storage().reference(forURL: imageURL)
                    imageRef.delete { error in
                        if let error = error {
                            print("Error deleting image file: \(error.localizedDescription)")
                        }
                    }
                }
                
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Real-time Updates
    /// Kayıtları gerçek zamanlı dinle
    func listenForRecordings(completion: @escaping (Result<[Recording], Error>) -> Void) -> ListenerRegistration {
        return db.collection(recordingsCollection)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let recordings = documents.compactMap { Recording(document: $0) }
                completion(.success(recordings))
            }
    }
} 