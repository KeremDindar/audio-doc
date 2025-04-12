import UIKit
import AVFoundation
import Speech
import SnapKit

/**
 * AudioRecordingViewController: Ses kaydetme ve kayıtları görüntüleme işlevselliğini yöneten ana sınıf
 * 
 * Bu ekran 3 temel işlevi yönetir:
 * 1. Ses kaydı yapma (başlatma, duraklama, durdurma)
 * 2. Firebase'e kaydedilmiş kayıtları görüntüleme
 * 3. Bir kayıt seçildiğinde Transcription ekranına geçiş yapma
 *
 * MVC Mimarisi:
 * - Controller: Bu sınıf (AudioRecordingViewController), kullanıcı etkileşimlerini işler
 * - Model: AudioRecordingManager ve FirebaseService üzerinden veri yönetimi sağlanır
 * - View: WaveformView ve RecordingTableViewCell gibi görsel bileşenler
 */
class AudioRecordingViewController: UIViewController {
    
    // MARK: - Properties
    
    /**
     * audioRecordingManager: Ses kayıt işlemlerini yöneten sınıf
     * Mikrofon izinleri, kayıt başlatma/durdurma, ses seviyesi ölçümü gibi işlemleri yönetir
     * Bu manager sayesinde view controller direkt olarak AVFoundation ile uğraşmaz
     */
    private var audioRecordingManager: AudioRecordingManager!
    
    /**
     * audioFileManager: Ses dosyalarının yönetimine ilişkin işlemleri yapan singleton sınıf
     * İndirme, saklama, dosya varlığını kontrol etme gibi işlemleri yönetir
     */
    private var audioFileManager: AudioFileManager!
    
    /**
     * Kayıt durumu ile ilgili özellikler
     * isPaused: Kaydın duraklatılıp duraklatılmadığını belirtir
     * recordingStartTime: Kaydın başlangıç zamanını tutar, süreyi hesaplamak için kullanılır
     * recordingDuration: Toplam kayıt süresini saniye cinsinden tutar
     * recordingURL: Kaydın yerel dosya sistemindeki konumunu tutar
     * audioMeterTimer: Ses seviyesini ve zaman etiketini güncellemek için kullanılan zamanlayıcı
     */
    private var isPaused = false
    private var recordingStartTime: Date?
    private var recordingDuration: TimeInterval = 0
    private var recordingURL: URL?
    private var audioMeterTimer: Timer?
    
    /**
     * Geçen süreyi AudioRecordingManager'dan alır
     * Hem aktif kayıt hem de duraklatıldığında geçen toplam süreyi doğru şekilde hesaplar
     */
    var elapsedTimeInSeconds: TimeInterval {
        return audioRecordingManager.elapsedTimeInSeconds
    }
    
    /**
     * Kayıtların listesini ve yükleme durumunu yöneten özellikler
     * recordings: Firebase'den yüklenen tüm kayıtları tutar
     * isLoading: Verilerin yüklenip yüklenmediğini belirtir, UI güncellemeleri için kullanılır
     */
    private var recordings: [Recording] = []
    private var isLoading = false
    
    // MARK: - UI Elements
    
    /**
     * titleLabel: Ekranın üst kısmında "Record" metnini gösteren etiket
     */
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Record"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    /**
     * timerLabel: Kayıt süresini dakika:saniye formatında gösteren etiket (00:00 şeklinde)
     * audioMeterTimer ile her 0.1 saniyede bir güncellenir
     */
    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 48, weight: .regular)
        return label
    }()
    
    /**
     * waveformView: Ses dalgalarını görselleştiren özel view
     * AudioRecordingManagerDelegate aracılığıyla gelen ses seviyesi verilerine göre güncellenir
     * Kullanıcıya görsel geri bildirim sağlar - ses yükseldikçe dalgalar büyür
     */
    private lazy var waveformView: WaveformView = {
        let view = WaveformView()
        view.backgroundColor = .clear
        return view
    }()
    
    /**
     * instructionLabel: Kullanıcıya ne yapması gerektiğini bildiren metin 
     * Kayıt durumuna göre "Press to Start", "Recording...", "Press to Resume" gibi metinler gösterir
     */
    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Press to Start"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        return label
    }()
    
    /**
     * microphoneButton: Kaydı başlatan ana buton
     * Dairesel tasarım, mikrofon simgesi içerir
     * Kullanıcı arayüzünün merkezi ögesidir
     */
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
    
    /**
     * pauseResumeButton: Kaydı durduran/devam ettiren buton
     * Duruma göre farklı simgeler gösterir (pause/play)
     * Kayıt başlamadan önce gizlidir
     */
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
    
    /**
     * finishButton: Kaydı bitiren/tamamlayan buton
     * Kırmızı bir stop simgesi içerir
     * Kayıt başlamadan önce gizlidir
     * Tıklandığında TranscriptionViewController'a geçiş yapar
     */
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
    
    /**
     * recordingsTableView: Geçmiş kayıtları listeleyen tablo
     * Firebase'den alınan verileri gösterir
     * Her kaydı bir RecordingTableViewCell içinde gösterir
     */
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
    
    /**
     * backButton: Ekranı kapatıp önceki ekrana döndüren buton
     */
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    /**
     * Yükleme göstergeleri ve boş durum etiketi
     * loadingView: Yükleme işlemi sırasında ekranın üzerine gelen yarı saydam panel
     * loadingIndicator: Dönen aktivite göstergesi
     * loadingLabel: Yükleme durumunu açıklayan metin
     * loadingIndicatorTableView: Tablo verilerinin yüklendiğini gösteren gösterge
     * emptyStateLabel: Kayıt bulunmadığında gösterilen metin
     */
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
    
    /**
     * viewDidLoad: View controller'ın hayat döngüsünde ilk kurulumun yapıldığı metod
     * Manager'ları başlatır, UI'ı kurar ve izinleri ister
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize managers
        audioRecordingManager = AudioRecordingManager()
        audioRecordingManager.delegate = self
        
        audioFileManager = AudioFileManager.shared
        
        setupUI()
        requestPermissions()
    }
    
    /**
     * viewWillAppear: View her görünmek üzere olduğunda çağrılan metod
     * UI'ı sıfırlar ve kayıtları yeniden yükler
     * TranscriptionViewController'dan döndükten sonra güncel listeyi göstermek için önemli
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetRecordingUI()
        loadRecordings() // Load recordings when view appears
    }
    
    // MARK: - Setup
    
    /**
     * setupUI: Kullanıcı arayüzünü kuran metod
     * Tüm UI bileşenlerini view'a ekler ve konumlandırır
     * SnapKit kütüphanesi ile Auto Layout kullanır
     */
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
    
    /**
     * requestPermissions: Mikrofon erişim izinlerini isteyen metod
     * Kullanıcı izin vermezse uyarı gösterilir ve izinlere yönlendirilir
     */
    private func requestPermissions() {
        audioRecordingManager.requestPermission { [weak self] allowed in
            if !allowed {
                self?.showRecordingPermissionAlert()
            }
        }
    }
    
    /**
     * showRecordingPermissionAlert: Mikrofon izni reddedildiğinde çağrılan metod
     * Kullanıcıyı Ayarlar uygulamasına yönlendirir
     * İznin neden gerekli olduğunu açıklar
     */
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
    
    /**
     * showAlert: Genel amaçlı uyarı gösterme metodudur
     * Hata durumları ve bilgilendirme amaçlı kullanılır
     */
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    /**
     * updateTimerLabel: Kayıt süresini ekranda gösteren metod
     * AudioRecordingManager'dan süreyi alır ve dakika:saniye formatında görüntüler
     * audioMeterTimer tarafından düzenli olarak çağrılır
     */
    private func updateTimerLabel() {
        let elapsed = audioRecordingManager.elapsedTimeInSeconds
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Recording Functions
    
    /**
     * startRecording: Ses kaydını başlatan metod
     * AudioRecordingManager'ı kullanarak kayıt işlemini başlatır
     * UI'ı kayıt moduna geçirir (mikrofon butonunu gizler, duraklatma ve bitirme butonlarını gösterir)
     * Ses seviyesi ölçümünü başlatır
     * Kayıt URL'ini saklar
     */
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
    
    /**
     * startAudioMetering: Ses seviyesi ölçümünü ve zamanlayıcıyı başlatan metod
     * Timer her 0.1 saniyede bir çalışarak timer label'ı ve waveform'u günceller
     * Kullanıcıya görsel ve sayısal geri bildirim sağlar
     */
    private func startAudioMetering() {
        audioMeterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimerLabel()
        }
        waveformView.startAnimation()
    }
    
    /**
     * finishButtonTapped: Kaydı tamamlama butonuna basıldığında çağrılan metod
     * 1. Ses seviyesini kontrol eder - eğer ses kaydedilmediyse uyarı gösterir
     * 2. Ses kaydedildiyse, kaydı durdurur ve TranscriptionViewController'a geçiş yapar
     * 3. Geçiş öncesi loading göstergesi gösterir
     * 
     * Not: Bu metod içinde dosya kontrolü yapılır - dosya bulunamazsa hata gösterilir
     */
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
                
                // TranscriptionViewController'a geçerken gerekli bilgileri aktarıyoruz:
                // - Ses dosyasının URL'i
                // - Kayıt tarihi
                // - Kayıt süresi
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
    
    /**
     * resetRecordingUI: Kayıt arayüzünü başlangıç durumuna getiren metod
     * Kayıt durdurulduğunda veya ekran ilk yüklendiğinde çağrılır
     * Tüm değerleri ve UI bileşenlerini sıfırlar
     */
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
    
    /**
     * showLoading: Yükleme göstergesini ekranda gösteren metod
     * İşlem sürerken kullanıcıya geri bildirim sağlar
     * Thread güvenliği için main thread kontrolü yapar
     */
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
    
    /**
     * hideLoading: Yükleme göstergesini gizleyen metod
     * İşlem tamamlandığında çağrılır
     * Thread güvenliği için main thread kontrolü yapar
     */
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
    
    /**
     * loadRecordings: Firebase'den kayıtları yükleyen metod
     * FirebaseService.shared üzerinden fetchAllRecordings metodunu çağırır
     * Yükleme sırasında ve sonrasında UI'ı günceller
     * Hata durumunda kullanıcıya bilgi verir
     */
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
    
    /**
     * updateEmptyState: Kayıt listesinin boş olup olmadığını kontrol eden ve UI'ı buna göre güncelleyen metod
     * Kayıt yoksa "No recordings available" mesajını gösterir
     * Kayıt varsa tabloyu gösterir
     */
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
    
    /**
     * microphoneButtonTapped: Mikrofon butonuna basıldığında çağrılan metod
     * startRecording() metodunu çağırarak kayıt işlemini başlatır
     */
    @objc private func microphoneButtonTapped() {
        startRecording()
    }
    
    /**
     * pauseResumeButtonTapped: Duraklat/Devam Et butonuna basıldığında çağrılan metod
     * Mevcut duruma göre kaydı duraklatır veya devam ettirir
     * UI'ı güncelleyerek kullanıcıya görsel geri bildirim sağlar
     * Button görüntüsünü ve konumunu durum değişikliğine göre günceller
     */
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
    
    /**
     * backButtonTapped: Geri butonuna basıldığında çağrılan metod
     * Ekranı kapatıp önceki ekrana döner
     */
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
}

/**
 * AudioRecordingManagerDelegate protokolünü uygulayan extension
 * Bu protokol, AudioRecordingManager sınıfından gelen callback'leri yönetir
 * Controller ve Manager arasındaki iletişimi sağlar (MVC yapısına uygun)
 */
extension AudioRecordingViewController: AudioRecordingManagerDelegate {
    /**
     * audioRecordingManager(_:didUpdateAudioLevel:): Ses seviyesi değiştiğinde çağrılır
     * Waveform görselleştirmesini günceller
     * AudioRecordingManager'ın ölçtüğü ses seviyesini kullanır
     * @param manager: Callback'i tetikleyen AudioRecordingManager nesnesi
     * @param level: Ölçülen ses seviyesi (0.0-1.0 aralığında normalize edilmiş)
     */
    func audioRecordingManager(_ manager: AudioRecordingManager, didUpdateAudioLevel level: Float) {
        // Update waveform with new audio level
        waveformView.updateAudioLevel(level)
    }
    
    /**
     * audioRecordingManager(_:didFinishRecordingSuccessfully:): Kayıt tamamlandığında çağrılır
     * Başarılı olmazsa kullanıcıya hata gösterir
     * @param manager: Callback'i tetikleyen AudioRecordingManager nesnesi
     * @param success: Kaydın başarılı olup olmadığını belirten boolean değer
     */
    func audioRecordingManager(_ manager: AudioRecordingManager, didFinishRecordingSuccessfully success: Bool) {
        if !success {
            showAlert(title: "Recording Error", message: "Recording failed to complete successfully")
        }
    }
    
    /**
     * audioRecordingManager(_:didFailWithError:): Kayıt sırasında hata oluştuğunda çağrılır
     * Hata mesajını kullanıcıya gösterir
     * @param manager: Callback'i tetikleyen AudioRecordingManager nesnesi
     * @param error: Oluşan hatanın detayları
     */
    func audioRecordingManager(_ manager: AudioRecordingManager, didFailWithError error: Error) {
        showAlert(title: "Error", message: error.localizedDescription)
    }
}

/**
 * UITableViewDelegate ve UITableViewDataSource protokollerini uygulayan extension
 * Kayıt listesinin görüntülenmesini ve seçim işlemlerini yönetir
 * Kayıtlar tablosunun veri kaynağı olarak hareket eder
 */
extension AudioRecordingViewController: UITableViewDelegate, UITableViewDataSource {
    /**
     * tableView(_:numberOfRowsInSection:): Tablodaki satır sayısını belirtir
     * Kayıt sayısı kadar satır gösterilir
     * @return: Görüntülenecek satır sayısı
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    /**
     * tableView(_:cellForRowAt:): Her bir tablo hücresinin içeriğini oluşturur
     * RecordingTableViewCell'i kayıt verileriyle yapılandırır
     * @param tableView: Tablo görünümü
     * @param indexPath: Hücrenin konumu (section ve row)
     * @return: Yapılandırılmış UITableViewCell
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecordingTableViewCell.identifier, for: indexPath) as? RecordingTableViewCell else {
            return UITableViewCell()
        }
        
        let recording = recordings[indexPath.row]
        cell.configure(with: recording, index: indexPath.row, isHomeView: false)
        
        return cell
    }
    
    /**
     * tableView(_:heightForRowAt:): Hücre yüksekliğini döndürür
     * Tutarlı bir düzen için sabit bir değer kullanılır
     * @return: Hücre yüksekliği (piksel cinsinden)
     */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    /**
     * tableView(_:estimatedHeightForRowAt:): Tahmini hücre yüksekliğini döndürür
     * Performans optimizasyonu için kullanılır
     * @return: Tahmini hücre yüksekliği (piksel cinsinden)
     */
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    /**
     * tableView(_:didSelectRowAt:): Bir kayıt seçildiğinde çağrılır
     * Seçilen kaydın ses dosyasını indirir ve TranscriptionViewController'a geçiş yapar
     * İndirme işlemi sırasında loading göstergesi gösterilir
     * 
     * İş akışı:
     * 1. Seçilen kaydın ses dosyası URL'ini alır
     * 2. Dosyayı yerel depolamaya indirir
     * 3. İndirme başarılıysa TranscriptionViewController'a geçer, aksi takdirde hata gösterir
     * 
     * @param tableView: Tablo görünümü
     * @param indexPath: Seçilen hücrenin konumu (section ve row)
     */
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

