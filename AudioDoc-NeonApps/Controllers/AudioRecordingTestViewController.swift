import UIKit
import AVFoundation
import Speech
import Photos
import SnapKit



class AudioRecordingTestViewController: UIViewController {
    
    // MARK: - Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession?
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var isPaused = false
    private var recordingDate = Date()
    private var recordingDuration: TimeInterval = 0
    
    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Audio Recording"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    private lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 32, weight: .semibold)
        label.textColor = .darkGray
        label.text = "00:00"
        return label
    }()
    
    private lazy var waveformView: WaveformView = {
        let view = WaveformView()
        return view
    }()
    
    private lazy var recordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var stopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
        button.tintColor = .systemRed
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.isHidden = true
        button.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var finishButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.tintColor = .systemGreen
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.isHidden = true
        button.addTarget(self, action: #selector(finishButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var resumeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.isHidden = true
        button.addTarget(self, action: #selector(resumeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap the microphone to start recording"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.textColor = .darkGray
        return label
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private var recordingTimer: Timer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRecordingSession()
        requestTranscribePermissions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        navigationController?.isNavigationBarHidden = true
        modalPresentationStyle = .fullScreen
        
        // Add UI elements to view
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(durationLabel)
        view.addSubview(statusLabel)
        view.addSubview(waveformView)
        view.addSubview(recordButton)
        view.addSubview(stopButton)
        view.addSubview(finishButton)
        view.addSubview(resumeButton)
        
        // Layout constraints
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(30)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.centerX.equalToSuperview()
        }
        
        durationLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(50)
            make.centerX.equalToSuperview()
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(durationLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        waveformView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(120)
        }
        
        let buttonSize: CGFloat = 60
        
        recordButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-50)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(buttonSize)
        }
        
        stopButton.snp.makeConstraints { make in
            make.centerY.equalTo(recordButton)
            make.trailing.equalTo(recordButton.snp.leading).offset(-40)
            make.width.height.equalTo(buttonSize)
        }
        
        finishButton.snp.makeConstraints { make in
            make.centerY.equalTo(recordButton)
            make.leading.equalTo(recordButton.snp.trailing).offset(40)
            make.width.height.equalTo(buttonSize)
        }
        
        resumeButton.snp.makeConstraints { make in
            make.center.equalTo(recordButton)
            make.width.height.equalTo(buttonSize)
        }
    }
    
    private func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
            recordingSession?.requestRecordPermission() { [weak self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self?.setupAudioEngine()
                    } else {
                        self?.statusLabel.text = "Microphone access denied. Please enable it in Settings."
                    }
                }
            }
        } catch {
            statusLabel.text = "Could not set up recording session: \(error.localizedDescription)"
        }
    }
    
    private func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Speech recognition authorized")
                } else {
                    print("Speech recognition permission was declined")
                }
            }
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        let format = inputNode?.inputFormat(forBus: 0)
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            guard let self = self else { return }
            
            let channelData = buffer.floatChannelData?[0]
            let frameCount = UInt(buffer.frameLength)
            
            var sum: Float = 0
            for i in 0..<Int(frameCount) {
                let sample = channelData?[i] ?? 0
                sum += sample * sample
            }
            
            let rms = sqrt(sum / Float(frameCount))
            // Normalize and scale
            let normalizedValue = min(1.0, rms * 2.5)
            
            DispatchQueue.main.async {
                self.waveformView.updateAudioLevel(normalizedValue)
            }
        }
    }
    
    // MARK: - Recording Functions
    private func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            recordingDate = Date()
            recordingDuration = 0
            
            // Update status label
            statusLabel.text = "Recording in progress..."
            
            // Show stop and finish buttons
            recordButton.isHidden = true
            stopButton.isHidden = false
            finishButton.isHidden = false
            
            // Start recording timer
            startRecordingTimer()
            
            // Start audio engine
            try audioEngine?.start()
        } catch {
            finishRecording(success: false)
            statusLabel.text = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    private func pauseRecording() {
        audioRecorder?.pause()
        isPaused = true
        
        // Update status label
        statusLabel.text = "Recording paused"
        
        // Hide stop and finish buttons, show resume button
        stopButton.isHidden = true
        finishButton.isHidden = false
        recordButton.isHidden = true
        resumeButton.isHidden = false
        
        // Pause recording timer
        recordingTimer?.invalidate()
    }
    
    private func resumeRecording() {
        audioRecorder?.record()
        isPaused = false
        
        // Update status label
        statusLabel.text = "Recording resumed..."
        
        // Show stop and finish buttons, hide resume button
        stopButton.isHidden = false
        finishButton.isHidden = false
        recordButton.isHidden = true
        resumeButton.isHidden = true
        
        // Resume recording timer
        startRecordingTimer()
    }
    
    private func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        
        // Stop recording timer
        recordingTimer?.invalidate()
        
        // Show appropriate UI
        recordButton.isHidden = false
        stopButton.isHidden = true
        finishButton.isHidden = true
        resumeButton.isHidden = true
        
        if success {
            statusLabel.text = "Recording completed"
            if let audioURL = audioRecorder?.url {
                // Navigate to TranscriptionViewController
                let transcriptionVC = TranscriptionViewController(audioURL: audioURL, recordingDate: recordingDate, recordingDuration: recordingDuration)
                transcriptionVC.modalPresentationStyle = .fullScreen
                present(transcriptionVC, animated: true)
            }
        } else {
            statusLabel.text = "Recording failed"
        }
        
        audioRecorder = nil
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 1
            self.updateDurationLabel()
        }
    }
    
    private func updateDurationLabel() {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // MARK: - Actions
    @objc private func recordButtonTapped() {
        startRecording()
    }
    
    @objc private func stopButtonTapped() {
        pauseRecording()
    }
    
    @objc private func finishButtonTapped() {
        finishRecording(success: true)
    }
    
    @objc private func resumeButtonTapped() {
        resumeRecording()
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecordingTestViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
} 
