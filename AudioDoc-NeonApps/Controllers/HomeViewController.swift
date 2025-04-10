import UIKit
import SnapKit
import FirebaseFirestore

// MARK: - HomeViewController
// Ana ekranı yöneten view controller
// Neden UIViewController'dan türetildi?
// - Standart iOS view controller yapısı
// - Temel view controller özelliklerini kullanabilmek için
// - Kolay entegrasyon ve genişletilebilirlik
// Alternatif: UICollectionViewController kullanılabilirdi ama bu durumda daha karmaşık bir yapı gerekirdi
class HomeViewController: UIViewController {
    
    // MARK: - Properties
    // Kayıtlar dizisi
    // Neden private var kullanıldı?
    // - Encapsulation (kapsülleme) prensibi
    // - Veri güvenliği
    // - Kontrollü erişim
    private var recordings: [Recording] = []
    
    // Yükleme durumu
    // Neden isLoading flag'i kullanıldı?
    // - Aynı anda birden fazla yükleme işlemini önlemek için
    // - UI güncellemelerini kontrol etmek için
    private var isLoading = false
    
    // MARK: - UI Components
    // Başlık etiketi
    // Neden UILabel kullanıldı?
    // - Basit metin gösterimi için en uygun bileşen
    // - Kolay özelleştirme
    // - Performanslı
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AudioDoc™"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    // Mikrofon ikonu
    // Neden UIImageView kullanıldı?
    // - Görsel içerik göstermek için en uygun bileşen
    // - SF Symbols entegrasyonu
    // - Kolay özelleştirme
    private let microphoneImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mic.circle.fill")
        imageView.tintColor = .systemBlue.withAlphaComponent(0.7)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // Durum etiketi
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Nothing Saved in Timeline"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    // Ekleme butonu
    // Neden UIButton kullanıldı?
    // - Kullanıcı etkileşimi için en uygun bileşen
    // - Dokunma olaylarını yönetmek için
    // - Görsel özelleştirme
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
    
    // Gradient katmanı
    // Neden CAGradientLayer kullanıldı?
    // - Performanslı gradient efekti
    // - Donanım hızlandırmalı
    // - Kolay animasyon
    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(named: "customBlue")!.cgColor,
            UIColor(named: "customPink")!.cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        return gradient
    }()
    
    // Tablo görünümü
    // Neden UITableView kullanıldı?
    // - Liste verilerini göstermek için en uygun bileşen
    // - Performanslı kaydırma
    // - Yeniden kullanılabilir hücreler
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(RecordingTableViewCell.self, forCellReuseIdentifier: RecordingTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        return tableView
    }()
    
    // Yükleme göstergesi
    // Neden UIActivityIndicatorView kullanıldı?
    // - Standart iOS yükleme göstergesi
    // - Kullanıcı dostu
    // - Kolay entegrasyon
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle Methods
    // View yüklendiğinde çağrılan metod
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
    
    // View düzeni güncellendiğinde çağrılan metod
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = addButton.bounds
        
        addButton.bringSubviewToFront(addButton.imageView!)
    }
    
    // View görünmeden önce çağrılan metod
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload recordings when view appears
        loadRecordings()
    }
    
    // View göründükten sonra çağrılan metod
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.bringSubviewToFront(addButton)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    // MARK: - UI Setup
    // UI bileşenlerini ayarlama
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Alt görünümleri ekleme
        view.addSubview(titleLabel)
        view.addSubview(microphoneImageView)
        view.addSubview(statusLabel)
        view.addSubview(addButton)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        
        gradientLayer.cornerRadius = 30
        addButton.layer.insertSublayer(gradientLayer, at: 0)
        
        // SnapKit ile kısıtlamaları ayarlama
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
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
        
        // Ekleme butonuna gölge efekti
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOpacity = 0.3
        addButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        addButton.layer.shadowRadius = 5
    }
    
    // Tablo görünümünü ayarlama
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - Data Loading
    // Kayıtları yükleme
    private func loadRecordings() {
        isLoading = true
        
        // Yükleme durumunu güncelle
        microphoneImageView.isHidden = true
        statusLabel.isHidden = true
        activityIndicator.startAnimating()
        
        // Firebase'den kayıtları yükle
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
    
    // Boş durumu güncelleme
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
    // Ekleme butonuna tıklandığında
    @objc private func addButtonTapped() {
        let audioVC = AudioRecordingViewController()
        let navController = UINavigationController(rootViewController: audioVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    // Uyarı gösterme
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Ses dosyasını indirme
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
        
        // Yükleme durumunu güncelle
        microphoneImageView.isHidden = true
        statusLabel.isHidden = true
        activityIndicator.startAnimating()
        
        // Firebase'den gerçek zamanlı dinleme başlat
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
    
    // Handle notification when a recording is added
    @objc private func recordingAdded() {
        print("Recording added notification received, reloading data...")
        loadRecordings()
    }
    
    deinit {
        // Remove observer when view controller is deallocated
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
            
            // Show confirmation alert
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
                // Show loading indicator
                let loadingAlert = UIAlertController(title: nil, message: "Deleting...", preferredStyle: .alert)
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.style = .medium
                loadingIndicator.startAnimating()
                loadingAlert.view.addSubview(loadingIndicator)
                self.present(loadingAlert, animated: true)
                
                // Delete from Firebase
                FirebaseService.shared.deleteRecording(recording) { result in
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true) {
                            switch result {
                            case .success:
                                // Remove from local array and table view
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
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Loading audio...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        present(loadingAlert, animated: true)
        
        // Download audio file
        if let audioURL = URL(string: recording.audioURL) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = audioURL.lastPathComponent
            let localURL = documentsPath.appendingPathComponent(fileName)
            
            // Check if file already exists
            if FileManager.default.fileExists(atPath: localURL.path) {
                loadingAlert.dismiss(animated: true) {
                    self.presentTranscriptionVC(with: recording, localURL: localURL)
                }
            } else {
                // Download the file
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
