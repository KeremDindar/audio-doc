import UIKit
import AVFoundation
import Speech
import SnapKit

class AudioRecordingViewController: UIViewController {
    
    // MARK: - Properties
    private var audioRecordingManager: AudioRecordingManager!
    private var audioFileManager: AudioFileManager!
    
    private var isPaused = false
    private var recordingStartTime: Date?
    private var recordingDuration: TimeInterval = 0
    private var recordingURL: URL?
    private var audioMeterTimer: Timer?
    
    var elapsedTimeInSeconds: TimeInterval {
        return audioRecordingManager.elapsedTimeInSeconds
    }
    
    // Real recordings list instead of mock data
    private var recordings: [Recording] = []
    private var isLoading = false
    
    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Record"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 48, weight: .regular)
        return label
    }()
    
    private lazy var waveformView: WaveformView = {
        let view = WaveformView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Press to Start"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        return label
    }()
    
    private lazy var microphoneButton: UIButton = {
        // Create a completely custom button
        let button = UIButton(type: .custom)
        
        // Configure the button to have a clear background
        button.backgroundColor = .clear
        
        // Create a configuration for the button with a large blue microphone icon
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "mic.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        config.baseForegroundColor = .systemBlue
        config.background.backgroundColor = .clear
        
        // Apply the configuration
        button.configuration = config
        
        // Add circular border
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.cornerRadius = 35
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(microphoneButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var pauseResumeButton: UIButton = {
        let button = UIButton(type: .custom)
        
        // Configure the button to have a clear background
        button.backgroundColor = .clear
        
        // Create a configuration for the button with a pause icon
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "pause.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        config.baseForegroundColor = .systemBlue
        config.background.backgroundColor = .clear
        
        // Apply the configuration
        button.configuration = config
        
        // Add circular border
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.cornerRadius = 35
        button.clipsToBounds = true
        
        button.isHidden = true
        button.addTarget(self, action: #selector(pauseResumeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var finishButton: UIButton = {
        let button = UIButton(type: .custom)
        
        // Configure the button to have a clear background
        button.backgroundColor = .clear
        
        // Create a configuration for the button with a stop icon
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "stop.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        config.baseForegroundColor = .red
        config.background.backgroundColor = .clear
        
        // Apply the configuration
        button.configuration = config
        
        // Add circular border
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.cornerRadius = 35
        button.clipsToBounds = true
        
        button.isHidden = true
        button.addTarget(self, action: #selector(finishButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var recordingsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(RecordingTableViewCell.self, forCellReuseIdentifier: RecordingTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 106
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        return tableView
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.layer.cornerRadius = 10
        view.isHidden = true
        return view
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        return indicator
    }()
    
    private lazy var loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Preparing transcription..."
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var loadingIndicatorTableView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No recordings available"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize managers
        audioRecordingManager = AudioRecordingManager()
        audioRecordingManager.delegate = self
        
        audioFileManager = AudioFileManager.shared
        
        setupUI()
        requestPermissions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetRecordingUI()
        loadRecordings() // Load recordings when view appears
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.isHidden = true
        
        // Add subviews
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(timerLabel)
        view.addSubview(waveformView)
        view.addSubview(instructionLabel)
        view.addSubview(microphoneButton)
        view.addSubview(pauseResumeButton)
        view.addSubview(finishButton)
        view.addSubview(recordingsTableView)
        
        // Setup loading view
        view.addSubview(loadingView)
        loadingView.addSubview(loadingIndicator)
        loadingView.addSubview(loadingLabel)
        
        // Add loading indicator and empty state label for table view
        view.addSubview(loadingIndicatorTableView)
        view.addSubview(emptyStateLabel)
        
        // Setup constraints with SnapKit
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.width.height.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
        }
        
        timerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
        }
        
        waveformView.snp.makeConstraints { make in
            make.top.equalTo(timerLabel.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
        }
        
        instructionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(waveformView.snp.bottom).offset(40)
        }
        
        microphoneButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(instructionLabel.snp.bottom).offset(20)
            make.width.height.equalTo(70)
        }
        
        pauseResumeButton.snp.makeConstraints { make in
            make.centerY.equalTo(microphoneButton)
            make.trailing.equalTo(microphoneButton.snp.leading).offset(-40)
            make.width.height.equalTo(70)
        }
        
        finishButton.snp.makeConstraints { make in
            make.centerY.equalTo(microphoneButton)
            make.leading.equalTo(microphoneButton.snp.trailing).offset(40)
            make.width.height.equalTo(70)
        }
        
        recordingsTableView.snp.makeConstraints { make in
            make.top.equalTo(microphoneButton.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(120)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(25)
        }
        
        loadingLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(loadingIndicator.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
        }
        
        loadingIndicatorTableView.snp.makeConstraints { make in
            make.center.equalTo(recordingsTableView)
        }
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalTo(recordingsTableView)
        }
    }
    
    private func requestPermissions() {
        audioRecordingManager.requestPermission { [weak self] allowed in
            if !allowed {
                self?.showRecordingPermissionAlert()
            }
        }
    }
    
    private func showRecordingPermissionAlert() {
        let alert = UIAlertController(
            title: "Microphone Access Denied",
            message: "Please allow microphone access in Settings to record audio.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func updateTimerLabel() {
        let elapsed = audioRecordingManager.elapsedTimeInSeconds
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Recording Functions
    private func startRecording() {
        if audioRecordingManager.startRecording() {
            // UI update
            microphoneButton.isHidden = true
            pauseResumeButton.isHidden = false
            finishButton.isHidden = false
            instructionLabel.text = "Recording..."
            
            // Start audio metering for visualization
            startAudioMetering()
            
            // Get recording URL
            recordingURL = audioRecordingManager.recordingURL
        } else {
            showAlert(title: "Error", message: "Failed to start recording")
        }
    }
    
    private func startAudioMetering() {
        audioMeterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimerLabel()
        }
        waveformView.startAnimation()
    }
    
    @objc private func finishButtonTapped() {
        // Check if any audio was detected
        if !audioRecordingManager.checkAudioLevels() {
            // No audio detected, show alert and stay on recording screen
            showAlert(title: "No Audio Detected", message: "No audio was detected during recording. Please try again.")
            audioRecordingManager.stopRecording()
            resetRecordingUI()
            return
        }
        
        // Audio was detected, proceed with normal flow
        showLoading()
        loadingLabel.text = "Processing audio..."
        
        // Stop UI updates first
        waveformView.stopAnimation()
        audioMeterTimer?.invalidate()
        
        // Use a slight delay for smoother transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            self.audioRecordingManager.stopRecording()
            
            // Navigate to transcription if we have a valid recording URL
            if let recordingURL = self.recordingURL, self.audioFileManager.fileExists(at: recordingURL) {
                let recordingDate = self.recordingStartTime ?? Date()
                let recordingDuration = self.audioRecordingManager.elapsedTimeInSeconds
                
                let transcriptionVC = TranscriptionViewController(
                    audioURL: recordingURL,
                    recordingDate: recordingDate,
                    recordingDuration: recordingDuration
                )
                transcriptionVC.modalPresentationStyle = .fullScreen
                
                // Present without hiding the loading indicator
                self.present(transcriptionVC, animated: true)
                
                // Hide loading after a short delay to avoid flicker during transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.hideLoading()
                }
            } else {
                self.hideLoading()
                self.showAlert(title: "Error", message: "Could not find the recorded audio file.")
            }
        }
    }
    
    // MARK: - UI Reset
    private func resetRecordingUI() {
        // Reset UI to initial state
        recordingDuration = 0
        
        // Reset timer
        timerLabel.text = "00:00"
        
        // Set up buttons
        microphoneButton.isHidden = false
        pauseResumeButton.isHidden = true
        finishButton.isHidden = true
        
        // Stop and reset waveform animation
        waveformView.stopAnimation()
        waveformView.startIdleAnimation()
        
        // Update instruction text
        instructionLabel.text = "Press to Start"
        
        // Clear timer
        audioMeterTimer?.invalidate()
        audioMeterTimer = nil
    }
    
    private func showLoading() {
        // Make sure we're on the main thread
        if Thread.isMainThread {
            loadingView.alpha = 1.0 // Make immediately visible
            loadingView.isHidden = false
            loadingIndicator.startAnimating()
        } else {
            DispatchQueue.main.async {
                self.loadingView.alpha = 1.0
                self.loadingView.isHidden = false
                self.loadingIndicator.startAnimating()
            }
        }
    }
    
    private func hideLoading() {
        // Make sure we're on the main thread
        if Thread.isMainThread {
            self.loadingView.alpha = 0.0
            self.loadingView.isHidden = true
            self.loadingIndicator.stopAnimating()
        } else {
            DispatchQueue.main.async {
                self.loadingView.alpha = 0.0
                self.loadingView.isHidden = true
                self.loadingIndicator.stopAnimating()
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadRecordings() {
        isLoading = true
        loadingIndicatorTableView.startAnimating()
        emptyStateLabel.isHidden = true
        
        FirebaseService.shared.fetchAllRecordings { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            self.loadingIndicatorTableView.stopAnimating()
            
            switch result {
            case .success(let fetchedRecordings):
                self.recordings = fetchedRecordings
                
                DispatchQueue.main.async {
                    self.recordingsTableView.reloadData()
                    self.updateEmptyState()
                }
                
            case .failure(let error):
                print("Failed to load recordings: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(title: "Loading Error", message: "Failed to load recordings. Please try again.")
                    self.updateEmptyState()
                }
            }
        }
    }
    
    private func updateEmptyState() {
        if recordings.isEmpty {
            emptyStateLabel.isHidden = false
            recordingsTableView.isHidden = true
        } else {
            emptyStateLabel.isHidden = true
            recordingsTableView.isHidden = false
        }
    }
    
    // MARK: - Actions
    @objc private func microphoneButtonTapped() {
        startRecording()
    }
    
    @objc private func pauseResumeButtonTapped() {
        if !audioRecordingManager.isPaused {
            // Pause recording
            audioRecordingManager.pauseRecording()
            
            // UI update - only show resume button
            instructionLabel.text = "Press to Resume"
            
            // Update button configuration with play icon
            var config = pauseResumeButton.configuration
            config?.image = UIImage(systemName: "play.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
            pauseResumeButton.configuration = config
            
            // Reposition buttons with SnapKit
            pauseResumeButton.snp.remakeConstraints { make in
                make.center.equalToSuperview() // Center in the view
                make.width.height.equalTo(70)
            }
            
            // Hide other buttons
            finishButton.isHidden = true
            
            // Stop audio metering
            audioMeterTimer?.invalidate()
            
            // Update layout
            view.layoutIfNeeded()
        } else {
            // Resume recording
            audioRecordingManager.resumeRecording()
            
            // Restart audio metering
            audioMeterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateTimerLabel()
            }
            
            // UI update - show all buttons
            instructionLabel.text = "Recording..."
            
            // Update button configuration with pause icon
            var config = pauseResumeButton.configuration
            config?.image = UIImage(systemName: "pause.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
            pauseResumeButton.configuration = config
            
            // Return buttons to original positions with SnapKit
            pauseResumeButton.snp.remakeConstraints { make in
                make.centerY.equalTo(microphoneButton)
                make.trailing.equalTo(microphoneButton.snp.leading).offset(-40)
                make.width.height.equalTo(70)
            }
            
            // Show other buttons
            finishButton.isHidden = false
            
            // Update layout
            view.layoutIfNeeded()
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - AudioRecordingManagerDelegate
extension AudioRecordingViewController: AudioRecordingManagerDelegate {
    func audioRecordingManager(_ manager: AudioRecordingManager, didUpdateAudioLevel level: Float) {
        // Update waveform with new audio level
        waveformView.updateAudioLevel(level)
    }
    
    func audioRecordingManager(_ manager: AudioRecordingManager, didFinishRecordingSuccessfully success: Bool) {
        if !success {
            showAlert(title: "Recording Error", message: "Recording failed to complete successfully")
        }
    }
    
    func audioRecordingManager(_ manager: AudioRecordingManager, didFailWithError error: Error) {
        showAlert(title: "Error", message: error.localizedDescription)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension AudioRecordingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecordingTableViewCell.identifier, for: indexPath) as? RecordingTableViewCell else {
            return UITableViewCell()
        }
        
        let recording = recordings[indexPath.row]
        cell.configure(with: recording, index: indexPath.row, isHomeView: false)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let recording = recordings[indexPath.row]
        guard let audioURL = URL(string: recording.audioURL) else {
            showAlert(title: "Error", message: "Invalid audio file URL")
            return
        }
        
        // Show loading
        loadingView.isHidden = false
        loadingIndicator.startAnimating()
        
        // Download audio file
        audioFileManager.downloadAudioFile(from: audioURL) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Hide loading
                self.loadingView.isHidden = true
                self.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let localURL):
                    // Create the transcription view controller with the correct initializer
                    let transcriptionVC = TranscriptionViewController(
                        audioURL: localURL,
                        recordingDate: recording.createdAt,
                        recordingDuration: TimeInterval(recording.duration),
                        recording: recording
                    )
                    transcriptionVC.modalPresentationStyle = .fullScreen
                    self.present(transcriptionVC, animated: true)
                    
                case .failure(let error):
                    self.showAlert(title: "Download Error", message: error.localizedDescription)
                }
            }
        }
    }
}

