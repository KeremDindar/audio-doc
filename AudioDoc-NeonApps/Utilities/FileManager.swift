import Foundation

// Rename to avoid conflict with System.FileManager
class AudioFileManager {
    // MARK: - Singleton
    static let shared = AudioFileManager()
    
    private init() {}
    
    // MARK: - File Operations
    
    /*  documentDirectory: Uygulamanın kullanıcı verilerini (örneğin ses kayıtları) sakladığı dizindir.
     
     userDomainMask: Kullanıcının ev dizinini ifade eder (iOS için bu, uygulamanın sandbox'ıdır).

     urls(...) dizisi döner, biz ilkini ([0]) alırız çünkü genelde tek bir URL döner.

      Bu dizin: file:///var/mobile/Containers/Data/Application/<UUID>/Documents/  */
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func generateRecordingURL() -> URL {
        let fileName = "recording-\(UUID().uuidString).m4a"
        return getDocumentsDirectory().appendingPathComponent(fileName) // appendingPathComponent fonksiyonu, verdiğin ismi Documents klasörüne ekler.
    }
    
    func deleteFile(at url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("Error deleting file: \(error.localizedDescription)")
            return false
        }
    }
    
    // Dosyanın belirtilen path’te var olup olmadığını kontrol eder.
    func fileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // MARK: - Audio File Download
    
    /*  localURL: İndirilen dosyayı nereye kaydedeceğiz (aynı isimle).
     
     Eğer dosya daha önce indirilmişse, tekrar indirmez.

     Yoksa:

     URLSession.shared.downloadTask: Dosyayı arka planda indirir.

     tempURL: Dosya önce geçici klasöre indirilir.

     Daha sonra moveItem(at:to:) ile bu dosyayı kalıcı klasöre taşır.
     */
    
    func downloadAudioFile(from remoteURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        // Create URL for local file
        let documentsDirectory = getDocumentsDirectory()
        let fileName = remoteURL.lastPathComponent
        let localURL = documentsDirectory.appendingPathComponent(fileName)
        
        // If file already exists, return it immediately
        if FileManager.default.fileExists(atPath: localURL.path) {
            completion(.success(localURL))
            return
        }
        
        // Download file
        let task = URLSession.shared.downloadTask(with: remoteURL) { tempURL, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let tempURL = tempURL else {
                let error = NSError(domain: "AudioFileManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download failed with no error"])
                completion(.failure(error))
                return
            }
            
            do {
                // Remove existing file if necessary
                if FileManager.default.fileExists(atPath: localURL.path) {
                    try FileManager.default.removeItem(at: localURL)
                }
                
                // Move downloaded file to permanent location
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                completion(.success(localURL))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - File Metadata
    
   /*  attributesOfItem: Belirli bir dosyanın meta verilerini döner.
    
    .size: Dosya boyutunu byte cinsinden verir.

    UInt64: Çok büyük dosyaları bile destekleyebilecek tamsayı türü.

*/
//    func getFileSize(at url: URL) -> UInt64? {
//        do {
//            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
//            return attributes[.size] as? UInt64
//        } catch {
//            print("Error getting file size: \(error.localizedDescription)")
//            return nil
//        }
//    }
//    
//    func getFileCreationDate(at url: URL) -> Date? {
//        do {
//            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
//            return attributes[.creationDate] as? Date
//        } catch {
//            print("Error getting file creation date: \(error.localizedDescription)")
//            return nil
//        }
//    }
} 
