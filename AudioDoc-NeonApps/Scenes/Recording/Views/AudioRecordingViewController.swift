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
    
    
    private var recordings: [Recording] = []
    private var isLoading = false
    
    // MARK: - UI Elements
    
        private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Record"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 25, weight: .bold)
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
        let button = UIButton(type: .custom)
        
        button.backgroundColor = .clear
        
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "mic.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        config.baseForegroundColor = .systemBlue
        config.background.backgroundColor = .clear
        
        button.configuration = config
        
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.cornerRadius = 35
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(microphoneButtonTapped), for: .touchUpInside)
        return button
    }()
    
    
    private lazy var pauseResumeButton: UIButton = {
        let button = UIButton(type: .custom)
        
        button.backgroundColor = .clear
        
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "pause.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        config.baseForegroundColor = .systemBlue
        config.background.backgroundColor = .clear
        
        button.configuration = config
        
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
        
        button.backgroundColor = .clear
        
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "stop.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        config.baseForegroundColor = .red
        config.background.backgroundColor = .clear
        
        button.configuration = config
        
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
    
   
    private lazy var recordsLabel: UILabel = {
        let label = UILabel()
        label.text = "Records"
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        return label
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
        
        audioRecordingManager = AudioRecordingManager()
        audioRecordingManager.delegate = self
        
        audioFileManager = AudioFileManager.shared
        
        setupUI()
        requestPermissions()
    }
    
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetRecordingUI()
        loadRecordings()
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
        view.addSubview(recordsLabel)
        view.addSubview(recordingsTableView)
        
        view.addSubview(loadingView)
        loadingView.addSubview(loadingIndicator)
        loadingView.addSubview(loadingLabel)
        
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
        
        recordsLabel.snp.makeConstraints { make in
            make.top.equalTo(microphoneButton.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(20)
        }
        
        recordingsTableView.snp.makeConstraints { make in
            make.top.equalTo(recordsLabel.snp.bottom).offset(10)
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
            microphoneButton.isHidden = true
            pauseResumeButton.isHidden = false
            finishButton.isHidden = false
            instructionLabel.text = "Recording..."
            
            startAudioMetering()
            
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
        if !audioRecordingManager.checkAudioLevels() {
            showAlert(title: "No Audio Detected", message: "No audio was detected during recording. Please try again.")
            audioRecordingManager.stopRecording()
            resetRecordingUI()
            return
        }
        
        showLoading()
        loadingLabel.text = "Processing audio..."
        
        waveformView.stopAnimation()
        audioMeterTimer?.invalidate()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            self.audioRecordingManager.stopRecording()
            
            if let recordingURL = self.recordingURL, self.audioFileManager.fileExists(at: recordingURL) {
                let recordingDate = self.recordingStartTime ?? Date()
                let recordingDuration = self.audioRecordingManager.elapsedTimeInSeconds
                
                
                let transcriptionVC = TranscriptionViewController(
                    audioURL: recordingURL,
                    recordingDate: recordingDate,
                    recordingDuration: recordingDuration
                )
                transcriptionVC.modalPresentationStyle = .fullScreen
                
                self.present(transcriptionVC, animated: true)
                
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
        
        timerLabel.text = "00:00"
        
        microphoneButton.isHidden = false
        pauseResumeButton.isHidden = true
        finishButton.isHidden = true
        
        waveformView.stopAnimation()
        waveformView.startIdleAnimation()
        
        instructionLabel.text = "Press to Start"
        
        audioMeterTimer?.invalidate()
        audioMeterTimer = nil
    }
  
    private func showLoading() {
        if Thread.isMainThread {
            loadingView.alpha = 1.0
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
            audioRecordingManager.pauseRecording()
            
            instructionLabel.text = "Press to Resume"
            
            var config = pauseResumeButton.configuration
            config?.image = UIImage(systemName: "play.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
            pauseResumeButton.configuration = config
            
            pauseResumeButton.snp.remakeConstraints { make in
                make.center.equalToSuperview() // Center in the view
                make.width.height.equalTo(70)
            }
            
            finishButton.isHidden = true
            
            audioMeterTimer?.invalidate()
            
            view.layoutIfNeeded()
        } else {
            audioRecordingManager.resumeRecording()
            
            audioMeterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateTimerLabel()
            }
            
            instructionLabel.text = "Recording..."
            
            var config = pauseResumeButton.configuration
            config?.image = UIImage(systemName: "pause.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
            pauseResumeButton.configuration = config
            
            pauseResumeButton.snp.remakeConstraints { make in
                make.centerY.equalTo(microphoneButton)
                make.trailing.equalTo(microphoneButton.snp.leading).offset(-40)
                make.width.height.equalTo(70)
            }
            
            // Show other buttons
            finishButton.isHidden = false
            
            view.layoutIfNeeded()
        }
    }
    
   
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
}


extension AudioRecordingViewController: AudioRecordingManagerDelegate {
  
    func audioRecordingManager(_ manager: AudioRecordingManager, didUpdateAudioLevel level: Float) {
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
        
        loadingView.isHidden = false
        loadingIndicator.startAnimating()
        
        audioFileManager.downloadAudioFile(from: audioURL) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingView.isHidden = true
                self.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let localURL):
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

