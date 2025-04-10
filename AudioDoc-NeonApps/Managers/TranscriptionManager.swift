import Foundation
import Speech
import AIProxy

protocol TranscriptionManagerDelegate: AnyObject {
    func transcriptionManager(_ manager: TranscriptionManager, didUpdateTranscription text: String, isFinal: Bool)
    func transcriptionManager(_ manager: TranscriptionManager, didFinishWithTranscription text: String)
    func transcriptionManager(_ manager: TranscriptionManager, didFailWithError error: Error)
}

class TranscriptionManager: NSObject {
    // MARK: - Properties
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var audioURL: URL
    private var transcription: String = ""
    private var summaryKeywords: [String] = []
    private lazy var openAIService = OpenAIManager(apiKey: "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")
    private var transcriptionCallback: ((String?, Error?) -> Void)?
    private var keywordsCallback: (([String]) -> Void)?
    
    weak var delegate: TranscriptionManagerDelegate?
    
    // MARK: - Initialization
    init(audioURL: URL) {
        self.audioURL = audioURL
        super.init()
        setupSpeechRecognizer()
    }
    
    // MARK: - Setup
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    // MARK: - Speech Recognition Methods
    func requestPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
    }
    
    func startTranscription(completion: @escaping (String?, Error?) -> Void) {
        self.transcriptionCallback = completion
        
        // Speech tanıma için izin kontrolü
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
            
            print("🔑 Speech recognition authorization status: \(authStatus.rawValue)")
            
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("✅ Speech recognition authorized")
                    self.performTranscription()
                case .denied:
                    print("❌ Speech recognition denied")
                    completion(nil, NSError(domain: "TranscriptionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech Recognition Denied"]))
                case .restricted:
                    print("⚠️ Speech recognition restricted")
                    completion(nil, NSError(domain: "TranscriptionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech Recognition Restricted"]))
                case .notDetermined:
                    print("❓ Speech recognition not determined")
                    completion(nil, NSError(domain: "TranscriptionError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech Recognition Not Determined"]))
                @unknown default:
                    print("⚠️ Unknown speech recognition status")
                    completion(nil, NSError(domain: "TranscriptionError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown Authorization Status"]))
                }
            }
        }
    }
    
    func generateKeywords(from text: String, completion: @escaping ([String]) -> Void) {
        self.keywordsCallback = completion
        generateSimpleKeywords(from: text)
    }
    
    // MARK: - Private Methods
    private func performTranscription() {
        print("🎤 Starting transcription process...")
        print("📂 Audio URL: \(audioURL.path)")
        
        // Dil olarak Türkçe'yi seçiyoruz
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
        print("🌍 Turkish recognizer available: \(recognizer?.isAvailable ?? false)")
        
        if recognizer == nil || !recognizer!.isAvailable {
            print("⚠️ Turkish recognizer not available, falling back to English")
            // Türkçe kullanılamıyorsa İngilizce'yi deneyelim
            let fallbackRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            print("🌍 English recognizer available: \(fallbackRecognizer?.isAvailable ?? false)")
            
            if fallbackRecognizer == nil || !fallbackRecognizer!.isAvailable {
                print("❌ No speech recognizer available")
                DispatchQueue.main.async {
                    self.transcriptionCallback?(nil, NSError(domain: "TranscriptionError", code: 5, userInfo: [NSLocalizedDescriptionKey: "No Speech Recognizer Available"]))
                }
                return
            }
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = true
        
        print("🎯 Starting recognition task...")
        
        // Tanıma işlemini başlat
        recognizer?.recognitionTask(with: request) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Transcription error: \(error.localizedDescription)")
                print("Error details: \(error)")
                DispatchQueue.main.async {
                    self.transcriptionCallback?(nil, error)
                }
                return
            }
            
            if let result = result {
                // Tanınan metni al
                let transcription = result.bestTranscription.formattedString
                print("📝 Received transcription: \(transcription)")
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Update the transcription text
                    self.transcription = transcription
                    
                    // Callback ile sonucu dön
                    self.transcriptionCallback?(transcription, nil)
                    
                    // İşlem tamamlandıysa anahtar kelimeleri oluştur
                    if result.isFinal {
                        print("✅ Transcription completed")
                        self.generateSimpleKeywords(from: transcription)
                    }
                }
            } else {
                print("⚠️ No result received from recognition task")
            }
        }
    }
    
    private func generateSimpleKeywords(from text: String) {
        // Basit bir anahtar kelime oluşturma işlemi
        // Gerçek yaşamda daha karmaşık NLP kullanılmalı
        
        var words = text.components(separatedBy: " ")
        
        // Stop words'leri kaldır (basit Türkçe örneği)
        let stopWords = ["ve", "veya", "ile", "bu", "şu", "o", "bir", "için", "gibi", "de", "da"]
        words = words.filter { !stopWords.contains($0.lowercased()) }
        
        // Kısa kelimeleri kaldır
        words = words.filter { $0.count > 3 }
        
        // Tekrarları kaldır
        words = Array(Set(words))
        
        // En fazla 5 anahtar kelime seç
        let keywords = Array(words.prefix(5))
        
        self.summaryKeywords = keywords
        self.keywordsCallback?(keywords)
    }
    
    // MARK: - Live Audio Transcription
    func startLiveTranscription() {
        // Check if there's an existing recognition task
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Initialize audio engine if needed
        if audioEngine == nil {
            audioEngine = AVAudioEngine()
        }
        
        // Create a new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            let error = NSError(domain: "TranscriptionManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
            delegate?.transcriptionManager(self, didFailWithError: error)
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        do {
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Configure audio engine
            let inputNode = audioEngine!.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // Install tap on input node
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            // Start audio engine
            audioEngine!.prepare()
            try audioEngine!.start()
            
            // Start recognition task
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.delegate?.transcriptionManager(self, didFailWithError: error)
                    self.stopLiveTranscription()
                    return
                }
                
                guard let result = result else { return }
                
                // Get transcription text
                let transcriptionText = result.bestTranscription.formattedString
                
                // Notify delegate about update
                self.delegate?.transcriptionManager(self, didUpdateTranscription: transcriptionText, isFinal: result.isFinal)
                
                // If final result, notify completion
                if result.isFinal {
                    self.delegate?.transcriptionManager(self, didFinishWithTranscription: transcriptionText)
                    self.stopLiveTranscription()
                }
            }
        } catch {
            delegate?.transcriptionManager(self, didFailWithError: error)
        }
    }
    
    func stopLiveTranscription() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
    }
} 