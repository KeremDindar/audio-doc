import Foundation
import Speech
import AIProxy

protocol TranscriptionManagerDelegate: AnyObject {
    func transcriptionManager(_ manager: TranscriptionManager, didUpdateTranscription text: String, isFinal: Bool)
    func transcriptionManager(_ manager: TranscriptionManager, didFinishWithTranscription text: String)
    func transcriptionManager(_ manager: TranscriptionManager, didFailWithError error: Error)
}

class TranscriptionManager: NSObject {
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var audioURL: URL
    private var transcription: String = ""
    private var summaryKeywords: [String] = []
    private var summary: String = ""
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
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
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
                    print("Speech recognition authorized")
                    self.performTranscription()
                case .denied:
                    print("Speech recognition denied")
                    completion(nil, NSError(domain: "TranscriptionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech Recognition Denied"]))
                case .restricted:
                    print(" Speech recognition restricted")
                    completion(nil, NSError(domain: "TranscriptionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech Recognition Restricted"]))
                case .notDetermined:
                    print(" Speech recognition not determined")
                    completion(nil, NSError(domain: "TranscriptionError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech Recognition Not Determined"]))
                @unknown default:
                    print("Unknown speech recognition status")
                    completion(nil, NSError(domain: "TranscriptionError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown Authorization Status"]))
                }
            }
        }
    }
    
    func generateKeywords(from text: String, completion: @escaping ([String]) -> Void) {
        // Kelime sayısını kontrol et
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        
        if wordCount < 5 {
            // Çok az kelime varsa, direkt olarak kelimeleri keyword olarak kullan
            let keywords = text.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            print("📝 Very short text detected, using words directly as keywords: \(keywords)")
            DispatchQueue.main.async {
                completion(keywords)
            }
            return
        }
        
        // Normal akışa devam et
        self.keywordsCallback = completion
        openAIService.delegate = self
        openAIService.generateSummaryKeywords(from: text)
    }
    

    
    // MARK: - Private Methods
    private func performTranscription() {
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
        
        if recognizer == nil || !recognizer!.isAvailable {
            // Türkçe kullanılamıyorsa İngilizce'yi deneyelim
            let fallbackRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            
            if fallbackRecognizer == nil || !fallbackRecognizer!.isAvailable {
                DispatchQueue.main.async {
                    self.transcriptionCallback?(nil, NSError(domain: "TranscriptionError", code: 5, userInfo: [NSLocalizedDescriptionKey: "No Speech Recognizer Available"]))
                }
                return
            }
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = true
        
        recognizer?.recognitionTask(with: request) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error details: \(error)")
                DispatchQueue.main.async {
                    self.transcriptionCallback?(nil, error)
                }
                return
            }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.transcription = transcription
                    self.transcriptionCallback?(transcription, nil)
                    
                    // Sadece final sonuç geldiğinde keyword üret
                    if result.isFinal {
                        self.generateKeywords(from: transcription) { keywords in
                            DispatchQueue.main.async {
                                self.summaryKeywords = keywords
                                self.keywordsCallback?(keywords)
                            }
                        }
                    }
                }
            } else {
                print(" No result received from recognition task")
            }
        }
    }
    
    // MARK: - Live Audio Transcription
    func startLiveTranscription() {
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        if audioEngine == nil {
            audioEngine = AVAudioEngine()
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            let error = NSError(domain: "TranscriptionManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
            delegate?.transcriptionManager(self, didFailWithError: error)
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let inputNode = audioEngine!.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine!.prepare()
            try audioEngine!.start()
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.delegate?.transcriptionManager(self, didFailWithError: error)
                    self.stopLiveTranscription()
                    return
                }
                
                guard let result = result else { return }
                
                let transcriptionText = result.bestTranscription.formattedString
                

                self.delegate?.transcriptionManager(self, didUpdateTranscription: transcriptionText, isFinal: result.isFinal)
                
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

extension TranscriptionManager: OpenAIManagerDelegate {
    func openAIManager(_ manager: OpenAIManager, didGenerateSummaryKeywords keywords: [String]) {
        let limitedKeywords = Array(keywords.prefix(6))
        DispatchQueue.main.async { [weak self] in
            self?.keywordsCallback?(limitedKeywords)
        }
    }
    
//    func openAIManager(_ manager: OpenAIManager, didGenerateSummary summary: String) {
//        self.summary = summary
//        self.summaryCallback?(summary)
//    }
    
    func openAIManager(_ manager: OpenAIManager, didFailWithError error: Error) {
        print("❌ OpenAI error: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.keywordsCallback?([])
        }
    }
} 
