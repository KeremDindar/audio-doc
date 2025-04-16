import Foundation
import AVFoundation

protocol AudioRecordingManagerDelegate: AnyObject {
    //Görsel bir ses seviyesi çubuğu göstermek gibi UI güncellemeleri için.
    func audioRecordingManager(_ manager: AudioRecordingManager, didUpdateAudioLevel level: Float)
    
    //Kayıt tamamlandıktan sonra başarılı mı oldu, iptal mi edildi, hata mı oldu bilgisini taşır.
    func audioRecordingManager(_ manager: AudioRecordingManager, didFinishRecordingSuccessfully success: Bool)
    
    func audioRecordingManager(_ manager: AudioRecordingManager, didFailWithError error: Error)
}

class AudioRecordingManager: NSObject {
    // MARK: - Properties
    private var audioRecorder: AVAudioRecorder?  //Sesin kaydedildiği ana nesne.
    private var recordingSession: AVAudioSession! //Mikrofonu kullanabilmek için Apple’ın sistemine açılan kanal
    private var audioLevelTimer: Timer?  // Her 0.1 saniyede bir sesin şiddetini ölçer
    
    // Audio level monitoring
    private var audioLevels: [Float] = []
    private let minimumAudioLevel: Float = 0.03  // Bu eşiğin üstünde bir ses varsa "kullanıcı konuştu" diyebiliyoruz.
    private let audioLevelCheckInterval: TimeInterval = 0.1 // Kaç saniyede bir ölçüm yapacağımız.
    
    
    // Recording state
    
    // private(set) demek: Dışarıdan okunabilir, içeriden (sınıf içinde) değiştirilebilir.
    
    private(set) var isRecording = false
    private(set) var isPaused = false
    private(set) var recordingStartTime: Date?
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var recordingURL: URL?
    
    weak var delegate: AudioRecordingManagerDelegate?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            delegate?.audioRecordingManager(self, didFailWithError: error)
        }
    }
    
    // MARK: - Recording Functions
    func requestPermission(completion: @escaping (Bool) -> Void) {
        recordingSession.requestRecordPermission { allowed in
            DispatchQueue.main.async {
                completion(allowed)
            }
        }
    }
    
    func startRecording() -> Bool {
        // Reset audio levels array
        audioLevels.removeAll()
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording-\(UUID().uuidString).m4a"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            delegate?.audioRecordingManager(self, didFailWithError: error)
            return false
        }
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Start recording
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            if audioRecorder?.record() == true {
                isRecording = true
                recordingURL = fileURL
                recordingStartTime = Date()
                startAudioLevelTracking()
                return true
            } else {
                return false
            }
        } catch {
            delegate?.audioRecordingManager(self, didFailWithError: error)
            return false
        }
    }
    
    func pauseRecording() {
        guard isRecording, !isPaused, let startTime = recordingStartTime else { return }
        
        audioRecorder?.pause()
        isPaused = true
        recordingDuration += Date().timeIntervalSince(startTime)
        stopAudioLevelTracking()
    }
    
    func resumeRecording() {
        guard isRecording, isPaused else { return }
        
        audioRecorder?.record()
        isPaused = false
        recordingStartTime = Date()
        startAudioLevelTracking()
    }
    
    func stopRecording() {
        guard let recorder = audioRecorder, recorder.isRecording || isPaused else {
            return
        }
        
        // Stop recording
        recorder.stop()
        audioRecorder = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            delegate?.audioRecordingManager(self, didFailWithError: error)
        }
        
        // Update state
        isRecording = false
        isPaused = false
        stopAudioLevelTracking()
    }
    
    // MARK: - Audio Level Tracking
    private func startAudioLevelTracking() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: audioLevelCheckInterval, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            let averagePower = recorder.averagePower(forChannel: 0)
            
            // More balanced audio level detection
            let boostFactor: Float = 1.5
            let boostOffset: Float = 40.0
            let adjustedPower = min(averagePower + boostOffset, 0) * boostFactor
            
            let normalizedLevel = pow(10, adjustedPower / 20)
            self.audioLevels.append(normalizedLevel)
            
            // Notify delegate about level update
            self.delegate?.audioRecordingManager(self, didUpdateAudioLevel: normalizedLevel)
        }
    }
    
    private func stopAudioLevelTracking() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }
    
    // MARK: - Audio Level Checking
    func checkAudioLevels() -> Bool {
        if audioLevels.isEmpty {
            return false
        }
        
        let sum = audioLevels.reduce(0, +)
        let average = sum / Float(audioLevels.count)
        
        let sortedLevels = audioLevels.sorted(by: >)
        
        let topSamplesCount = max(Int(Float(audioLevels.count) * 0.1), 1)
        let topSamples = Array(sortedLevels.prefix(topSamplesCount))
        let topAverage = topSamples.reduce(0, +) / Float(topSamples.count)
        
        let hasSignificantPeaks = topAverage > minimumAudioLevel * 5
        
        let hasAverageAudio = average > minimumAudioLevel
        
        return hasSignificantPeaks || hasAverageAudio
    }
    
    // MARK: - Helper Functions
    var elapsedTimeInSeconds: TimeInterval {
        if isPaused {
            return recordingDuration
        } else if let startTime = recordingStartTime {
            return Date().timeIntervalSince(startTime) + recordingDuration
        }
        return 0
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecordingManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        delegate?.audioRecordingManager(self, didFinishRecordingSuccessfully: flag)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            delegate?.audioRecordingManager(self, didFailWithError: error)
        }
    }
} 
