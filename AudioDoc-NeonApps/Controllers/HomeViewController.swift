import UIKit
import SnapKit
import FirebaseFirestore

// MARK: - HomeViewController

class HomeViewController: UIViewController {
    
   
    private var recordings: [Recording] = []
    
   
    private var isLoading = false
    
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AudioDoc™"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    
    private let microphoneImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mic.circle.fill")
        imageView.tintColor = .systemBlue.withAlphaComponent(0.7)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Nothing Saved in Timeline"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    
    private lazy var addButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        let image = UIImage(systemName: "plus", withConfiguration: config)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 30
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    
    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.customBlue.cgColor,
            UIColor.customPink.cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        return gradient
    }()
    
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(RecordingTableViewCell.self, forCellReuseIdentifier: RecordingTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        return tableView
    }()
    
   
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        startListeningForRecordings()
        
        // Add observer for recording added notification
        NotificationCenter.default.addObserver(self, 
                                             selector: #selector(recordingAdded), 
                                             name: Notification.Name("RecordingAdded"), 
                                             object: nil)
        
        view.bringSubviewToFront(addButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = addButton.bounds
        
        addButton.bringSubviewToFront(addButton.imageView!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecordings()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.bringSubviewToFront(addButton)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(microphoneImageView)
        view.addSubview(statusLabel)
        view.addSubview(addButton)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        
        gradientLayer.cornerRadius = 30
        addButton.layer.insertSublayer(gradientLayer, at: 0)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.centerX.equalToSuperview()
        }
        
        microphoneImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
            make.width.height.equalTo(80)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(microphoneImageView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
        }
        
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-25)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-25)
            make.width.height.equalTo(60)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOpacity = 0.3
        addButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        addButton.layer.shadowRadius = 5
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - Data Loading
    private func loadRecordings() {
        isLoading = true
        
        microphoneImageView.isHidden = true
        statusLabel.isHidden = true
        activityIndicator.startAnimating()
        
        FirebaseService.shared.fetchAllRecordings { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            self.activityIndicator.stopAnimating()
            
            switch result {
            case .success(let fetchedRecordings):
                self.recordings = fetchedRecordings
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
                
            case .failure(let error):
                print("Failed to load recordings: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(title: "Yükleme Hatası", message: "Kayıtlar yüklenirken bir hata oluştu. Lütfen tekrar deneyin.")
                    self.updateEmptyState()
                }
            }
        }
    }
    
    private func updateEmptyState() {
        if recordings.isEmpty {
            tableView.isHidden = true
            microphoneImageView.isHidden = false
            statusLabel.isHidden = false
        } else {
            tableView.isHidden = false
            microphoneImageView.isHidden = true
            statusLabel.isHidden = true
        }
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        let audioVC = AudioRecordingViewController()
        let navController = UINavigationController(rootViewController: audioVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func downloadAudioFile(from url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = url.lastPathComponent
        let localURL = documentsDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: localURL.path) {
            completion(.success(localURL))
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(NSError(domain: "com.audiodoc.download", code: 1, userInfo: [NSLocalizedDescriptionKey: "Geçici dosya bulunamadı"])))
                return
            }
            
            do {
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                completion(.success(localURL))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private var listener: ListenerRegistration?
    
    private func startListeningForRecordings() {
        isLoading = true
        
        microphoneImageView.isHidden = true
        statusLabel.isHidden = true
        activityIndicator.startAnimating()
        
        listener = FirebaseService.shared.listenForRecordings { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            self.activityIndicator.stopAnimating()
            
            switch result {
            case .success(let fetchedRecordings):
                self.recordings = fetchedRecordings
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
                
            case .failure(let error):
                print("Failed to load recordings: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(title: "Yükleme Hatası", message: "Kayıtlar yüklenirken bir hata oluştu. Lütfen tekrar deneyin.")
                    self.updateEmptyState()
                }
            }
        }
    }
    
    @objc private func recordingAdded() {
        print("Recording added notification received, reloading data...")
        loadRecordings()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecordingTableViewCell.identifier, for: indexPath) as? RecordingTableViewCell else {
            return UITableViewCell()
        }
        
        let recording = recordings[indexPath.row]
        cell.configure(with: recording, index: indexPath.row, isHomeView: true)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            let recording = self.recordings[indexPath.row]
            
            let alert = UIAlertController(
                title: "Delete Recording",
                message: "Are you sure you want to delete this recording? This action cannot be undone.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
//                completion(false)
//            })
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                let loadingAlert = UIAlertController(title: nil, message: "Deleting...", preferredStyle: .alert)
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.style = .medium
                loadingIndicator.startAnimating()
                loadingAlert.view.addSubview(loadingIndicator)
                self.present(loadingAlert, animated: true)
                
                FirebaseService.shared.deleteRecording(recording) { result in
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true) {
                            switch result {
                            case .success:
                                self.recordings.remove(at: indexPath.row)
                                tableView.deleteRows(at: [indexPath], with: .automatic)
                                self.updateEmptyState()
                                completion(true)
                                
                            case .failure(let error):
                                self.showAlert(title: "Error", message: "Failed to delete recording: \(error.localizedDescription)")
                                completion(false)
                            }
                        }
                    }
                }
            })
            
            self.present(alert, animated: true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recording = recordings[indexPath.row]
        
        let loadingAlert = UIAlertController(title: nil, message: "Loading audio...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        present(loadingAlert, animated: true)
        
        if let audioURL = URL(string: recording.audioURL) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = audioURL.lastPathComponent
            let localURL = documentsPath.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: localURL.path) {
                loadingAlert.dismiss(animated: true) {
                    self.presentTranscriptionVC(with: recording, localURL: localURL)
                }
            } else {
                let downloadTask = URLSession.shared.downloadTask(with: audioURL) { tempURL, response, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            loadingAlert.dismiss(animated: true) {
                                self.showAlert(title: "Error", message: "Failed to download audio: \(error.localizedDescription)")
                            }
                            return
                        }
                        
                        guard let tempURL = tempURL else {
                            loadingAlert.dismiss(animated: true) {
                                self.showAlert(title: "Error", message: "Failed to download audio file")
                            }
                            return
                        }
                        
                        do {
                            if FileManager.default.fileExists(atPath: localURL.path) {
                                try FileManager.default.removeItem(at: localURL)
                            }
                            try FileManager.default.moveItem(at: tempURL, to: localURL)
                            
                            loadingAlert.dismiss(animated: true) {
                                self.presentTranscriptionVC(with: recording, localURL: localURL)
                            }
                        } catch {
                            loadingAlert.dismiss(animated: true) {
                                self.showAlert(title: "Error", message: "Failed to save audio file: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                downloadTask.resume()
            }
        }
    }
    
    private func presentTranscriptionVC(with recording: Recording, localURL: URL) {
        let transcriptionVC = TranscriptionViewController(
            audioURL: localURL,
            recordingDate: recording.createdAt,
            recordingDuration: TimeInterval(recording.duration),
            recording: recording
        )
        transcriptionVC.modalPresentationStyle = .fullScreen
        present(transcriptionVC, animated: true)
    }
} 
