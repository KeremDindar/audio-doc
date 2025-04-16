import UIKit
import NeonSDK
import AIProxy
import AVFoundation
import Speech
import Photos
import SnapKit

class TranscriptionViewController: UIViewController {
    
    // MARK: - Properties
    private var audioURL: URL
    private var recordingDate: Date
    private var recordingDuration: TimeInterval
     var selectedImage: UIImage?
    private var transcription: String = ""
    private var summary: String = ""
    private var summaryKeywords: [String] = []
    private var tags: [Tag] = []
    private let maxTagCount = 3
     var recording: Recording?
    
    // Manager instances
     lazy var audioPlayerManager: AudioPlayerManager = {
        let manager = AudioPlayerManager(audioURL: audioURL)
        manager.delegate = self
        return manager
    }()
    
    internal lazy var transcriptionManager: TranscriptionManager = {
        let manager = TranscriptionManager(audioURL: audioURL)
        return manager
    }()
    
    // MARK: - UI Elements
     lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .darkGray
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let dateString = dateFormatter.string(from: recordingDate)
        let timeString = timeFormatter.string(from: recordingDate)
        
        label.text = "\(dateString)    \(timeString)"
        return label
    }()
    
     lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .darkGray
        
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        label.text = String(format: "%02d:%02d", minutes, seconds)
        
        return label
    }()
    
     lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Recording"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
     lazy var summaryLabel: UILabel = {
        let label = UILabel()
        label.text = "Summary Keywords"
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 22, weight: .bold)
        return label
    }()
    
     lazy var keywordsLabel: UILabel = {
        let label = UILabel()
        label.text = "No summary keywords..."
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    
     lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.backgroundColor = .systemGray5
        imageView.tintColor = .gray
        return imageView
    }()
    
     lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Lara White"
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()
    
     lazy var transcriptionTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .darkGray
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.text = "Transcribing audio..."
        textView.isScrollEnabled = false
        return textView
    }()
    
     lazy var audioControlsView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 20
        return view
    }()
    
     lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .darkGray
        label.textAlignment = .left
        return label
    }()
    
     lazy var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .darkGray
        label.textAlignment = .right
        return label
    }()
    
     lazy var backwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gobackward.5"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(backwardButtonTapped), for: .touchUpInside)
        return button
    }()
    
     lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.tintColor = .darkGray
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        return button
    }()
    
    
    lazy var forwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "goforward.5"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(forwardButtonTapped), for: .touchUpInside)
        return button
    }()
    
     lazy var speedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("1x", for: .normal)
        button.tintColor = .darkGray
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(speedButtonTapped), for: .touchUpInside)
        return button
    }()
    
     lazy var galleryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "photo"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(galleryButtonTapped), for: .touchUpInside)
        return button
    }()
    
     lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
     lazy var moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(moreButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
     lazy var selectedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        imageView.layer.cornerRadius = 8
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.systemGray4.cgColor
        return imageView
    }()
    
     lazy var deleteImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(deleteImageButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
     lazy var tagsScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
     lazy var tagsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()
    
     lazy var tagInputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
     lazy var tagInputView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()
    
     lazy var tagInputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Write Tag"
        textField.borderStyle = .none
        textField.font = .systemFont(ofSize: 16)
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing
        return textField
    }()
    
     lazy var tagInputAddButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Tag", for: .normal)
        button.backgroundColor = .button
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(addTagButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Add progress slider
     lazy var progressSlider: UISlider = {
        let slider = UISlider()
        slider.minimumTrackTintColor = UIColor(named: "ButtonColor")
        slider.maximumTrackTintColor = .systemGray5
        slider.setThumbImage(UIImage(systemName: "circle.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 6)), for: .normal)
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchUp), for: [.touchUpInside, .touchUpOutside])
        return slider
    }()
    
    // Add loading view
     lazy var loadingContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.7)
        view.isHidden = true
        view.alpha = 0
        return view
    }()
    
     lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
     lazy var loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Processing..."
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Initialization
    
    init(audioURL: URL, recordingDate: Date, recordingDuration: TimeInterval, recording: Recording? = nil) {
        print("TranscriptionViewController init with audioURL: \(audioURL.path)")
        
        // Dosya var mı kontrol et
        if !FileManager.default.fileExists(atPath: audioURL.path) {
            print("WARNING: Audio file does not exist at path: \(audioURL.path)")
        } else {
            print(" Audio file exists at path: \(audioURL.path)")
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: audioURL.path)
                if let fileSize = attributes[.size] as? NSNumber {
                    print("Audio file size: \(fileSize.intValue) bytes")
                }
            } catch {
                print("Error getting file attributes: \(error)")
            }
        }
        
        self.audioURL = audioURL
        self.recordingDate = recordingDate
        self.recordingDuration = recordingDuration
        self.recording = recording
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        totalTimeLabel.text = audioPlayerManager.formatTime(recordingDuration)
        
        if let recording = recording {
            titleLabel.text = recording.title
            
            galleryButton.isEnabled = false
            galleryButton.tintColor = .systemGray3
        } else {
            let defaults = UserDefaults.standard
            let nextVoiceNumber = defaults.integer(forKey: "nextVoiceNumber")
            let formattedNumber = String(format: "%04d", nextVoiceNumber > 0 ? nextVoiceNumber : 1)
            titleLabel.text = "Voice \(formattedNumber)"
        }
        
        tagInputTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutsideTagInput))
        tagInputContainerView.addGestureRecognizer(tapGesture)
        
        transcriptionTextView.text = "Transcribing audio..."
        transcriptionTextView.isHidden = false
        transcriptionTextView.backgroundColor = .clear
        transcriptionTextView.isEditable = false
        
        if let recording = recording {
            loadExistingRecordingData(recording)
        } else {
            print(" Starting transcription process in viewDidLoad")
            startTranscription()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        audioPlayerManager.cleanup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        audioPlayerManager.cleanup()
    }
    
    // MARK: - Helper Methods
    
    private func loadExistingRecordingData(_ recording: Recording) {
        self.transcription = recording.transcription
        transcriptionTextView.text = recording.transcription
        
        self.summaryKeywords = recording.summaryKeywords
        if recording.summaryKeywords.isEmpty {
            self.keywordsLabel.text = "No Summary Keywords"
        } else {
            self.keywordsLabel.text = recording.summaryKeywords.joined(separator: ", ")
        }
        
        if let imageURLString = recording.imageURL {
            loadImage(from: imageURLString)
            deleteImageButton.isHidden = true
        }
        
        if !recording.tags.isEmpty {
            recording.tags.forEach { tagText in
                let tag = Tag(text: tagText, color: Tag.randomColor())
                addTag(tag)
            }
        }
    }
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data) else {
                print("Error loading image: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.setSelectedImage(image)
            }
        }.resume()
    }
    
    private func startTranscription() {
        transcriptionManager.startTranscription { [weak self] text, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Transcription error: \(error)")
                return
            }
            
            if let text = text {
                DispatchQueue.main.async {
                    self.transcription = text
                    self.transcriptionTextView.text = text
                    
                    // Kelime sayısını kontrol et
                    let wordCount = text.components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }
                        .count
                    
                    self.transcriptionManager.generateKeywords(from: text) { keywords in
                        DispatchQueue.main.async {
                            self.summaryKeywords = keywords
                            
                            if keywords.isEmpty {
                                self.keywordsLabel.text = "No Summary Keywords"
                            } else if wordCount < 5 {
                                self.keywordsLabel.text = keywords.joined(separator: ", ")
                            } else {
                                self.keywordsLabel.text = keywords.joined(separator: ", ")
                            }
                        }
                    }
                }
            }
        }
    }
    
    internal func updatePlayerUI() {
        currentTimeLabel.text = audioPlayerManager.formatTime(audioPlayerManager.currentTime)
        totalTimeLabel.text = audioPlayerManager.formatTime(audioPlayerManager.duration)
        progressSlider.value = Float(audioPlayerManager.currentTime / max(1, audioPlayerManager.duration))
        
        let imageName = audioPlayerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    // MARK: - User Actions
    
    @objc internal func playButtonTapped() {
        audioPlayerManager.togglePlayback()
    }
    
    @objc internal func backwardButtonTapped() {
        audioPlayerManager.skipBackward()
    }
    
    @objc internal func forwardButtonTapped() {
        audioPlayerManager.skipForward()
    }
    
    @objc internal func sliderValueChanged() {
        let time = TimeInterval(progressSlider.value) * audioPlayerManager.duration
        currentTimeLabel.text = audioPlayerManager.formatTime(time)
    }
    
    @objc internal func sliderTouchUp() {
        let time = TimeInterval(progressSlider.value) * audioPlayerManager.duration
        audioPlayerManager.seek(to: time)
        
        if !audioPlayerManager.isPlaying {
            audioPlayerManager.play()
        }
    }
    
    @objc internal func speedButtonTapped() {
        switch audioPlayerManager.playbackRate {
        case 1.0:
            audioPlayerManager.playbackRate = 1.5
            speedButton.setTitle("1.5x", for: .normal)
        case 1.5:
            audioPlayerManager.playbackRate = 2.0
            speedButton.setTitle("2x", for: .normal)
        case 2.0:
            audioPlayerManager.playbackRate = 0.5
            speedButton.setTitle("0.5x", for: .normal)
        default:
            audioPlayerManager.playbackRate = 1.0
            speedButton.setTitle("1x", for: .normal)
        }
    }
    
    @objc internal func galleryButtonTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    @objc internal func backButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc internal func moreButtonTapped(_ sender: UIButton) {
        var menuItems: [UIAction] = []

        if recording != nil {
            // Sadece Copy, Share ve Delete
            menuItems = [
                UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
                    self?.copyTranscription()
                },
                UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                    self?.shareRecording()
                },
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                    self?.deleteRecording()
                }
            ]
        } else {
            // Tüm seçenekler
            menuItems = [
                UIAction(title: "Tag", image: UIImage(systemName: "tag")) { [weak self] _ in
                    self?.tagRecording()
                },
                UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
                    self?.copyTranscription()
                },
                UIAction(title: "Save", image: UIImage(systemName: "tray.and.arrow.down")) { [weak self] _ in
                    self?.saveRecording()
                },
                UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                    self?.shareRecording()
                },
                UIAction(title: "Change Template", image: UIImage(systemName: "square.and.pencil")) { [weak self] _ in
                    self?.changeTemplate()
                },
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                    self?.deleteRecordingFromMenu()
                }
            ]
        }

        let menu = UIMenu(title: "", children: menuItems)
        sender.showsMenuAsPrimaryAction = true
        sender.menu = menu
    }
    
    @objc internal func deleteImageButtonTapped() {
        let alert = UIAlertController(title: "Would you like to remove this photo?", message: "This action cannot be undone.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.removeSelectedImage()
        })
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc internal func tagInputViewTapped(_ sender: UITapGestureRecognizer) {
        // Kullanıcı tag input view'a tıkladığında klavyeyi aç
        tagInputTextField.becomeFirstResponder()
    }
    
    @objc internal func tagInputTextFieldTapped(_ sender: UITextField) {
        sender.becomeFirstResponder()
    }
    
    @objc internal func handleTapOutsideTagInput(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: tagInputView)
        if !tagInputView.bounds.contains(location) {
            print("Tapped outside tag input view")
            hideTagInput()
        }
    }
    
    @objc internal func addTagButtonTapped() {
        guard let tagText = tagInputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !tagText.isEmpty else {
            showToast(message: "Please enter a tag")
            return
        }
        
        hideTagInput()
        
        let tag = Tag(text: tagText, color: Tag.randomColor())
        addTag(tag)
    }
    
    @objc internal func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: 0.3) {
                self.tagInputView.transform = CGAffineTransform(translationX: 0, y: -keyboardSize.height / 2)
            }
        }
    }
    
    @objc internal func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.tagInputView.transform = .identity
        }
    }
    
    // MARK: - Action Handlers
    
    private func tagRecording() {
        if tags.count >= maxTagCount {
            showToast(message: "You can add a maximum of \(maxTagCount) tags")
            return
        }
        
        tagInputTextField.text = ""
        tagInputContainerView.isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.tagInputContainerView.alpha = 1
        }, completion: { _ in
            self.setupKeyboardObservers()
        })
    }
    
    private func setupKeyboardObservers() {
        // Önceki dinleyicileri temizle
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Yeni dinleyicileri ekle
        NotificationCenter.default.addObserver(self, 
                                             selector: #selector(keyboardWillShow),
                                             name: UIResponder.keyboardWillShowNotification,
                                             object: nil)
        NotificationCenter.default.addObserver(self, 
                                             selector: #selector(keyboardWillHide),
                                             name: UIResponder.keyboardWillHideNotification,
                                             object: nil)
    }
    
    internal func hideTagInput() {
        // Klavyeyi kapat ve input'u gizle
        tagInputTextField.resignFirstResponder()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.tagInputContainerView.alpha = 0
            self.tagInputView.transform = .identity
        }) { _ in
            self.tagInputContainerView.isHidden = true
            
            // Notification dinleyicilerini kaldır
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
    
    internal func addTag(_ tag: Tag) {
        if tags.count >= maxTagCount {
            showToast(message: "You can add a maximum of \(maxTagCount) tags")
            return
        }
        
        tags.append(tag)
        
        let tagView = createTagView(for: tag)
        tagsStackView.addArrangedSubview(tagView)
        
        tagsStackView.layoutIfNeeded()
        tagsScrollView.contentSize = tagsStackView.bounds.size
    }
    
    internal func createTagView(for tag: Tag) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = tag.color.withAlphaComponent(0.2)
        containerView.layer.cornerRadius = 16
        
        let label = UILabel()
        label.text = tag.text
        label.textColor = tag.color
        label.font = .systemFont(ofSize: 14, weight: .medium)
        
        containerView.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        return containerView
    }
    
    private func copyTranscription() {
        UIPasteboard.general.string = transcriptionTextView.text
        showSuccessIndicator(message: "Copied")
    }
    
    private func saveRecording() {
        
        
        if !FileManager.default.fileExists(atPath: audioURL.path) {
            hideLoading()
            showAlert(title: "Hata", message: "Ses dosyası bulunamadı. Kayıt yapılamadı.")
            return
        }
        
        print("Uploading audio from path: \(audioURL.path)")
        
        FirebaseService.shared.uploadAudio(from: audioURL) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let audioURL):
                print("Audio uploaded successfully: \(audioURL)")
                // Resim seçilmişse yükle, seçilmemişse direkt kayıt oluştur
                if let selectedImage = self.selectedImage {
                    FirebaseService.shared.uploadImage(selectedImage) { [weak self] imageResult in
                        guard let self = self else { return }
                        
                        switch imageResult {
                        case .success(let imageURL):
                            self.createAndSaveRecording(audioURL: audioURL, imageURL: imageURL)
                            
                        case .failure(let error):
                            print("Failed to upload image: \(error.localizedDescription)")
                            self.createAndSaveRecording(audioURL: audioURL, imageURL: nil)
                        }
                    }
                } else {
                    self.createAndSaveRecording(audioURL: audioURL, imageURL: nil)
                }
                
            case .failure(let error):
                self.hideLoading()
                print("Failed to upload audio: \(error.localizedDescription)")
                print("Error details: \(error)")
                self.showAlert(title: "Upload Failed", message: "Could not upload recording: \(error.localizedDescription)")
            }
        }
    }
    
    private func createAndSaveRecording(audioURL: String, imageURL: String?) {
        let tagTexts = tags.map { $0.text }
        
        let defaults = UserDefaults.standard
        let nextVoiceNumber = defaults.integer(forKey: "nextVoiceNumber")
        
        let formattedNumber = String(format: "%04d", nextVoiceNumber > 0 ? nextVoiceNumber : 1)
        let title = "Voice \(formattedNumber)"
        
        defaults.set(nextVoiceNumber > 0 ? nextVoiceNumber + 1 : 2, forKey: "nextVoiceNumber")
        
        let recording = Recording(
            title: title,
            summaryKeywords: self.summaryKeywords,
            transcription: self.transcription,
            createdAt: self.recordingDate,
            duration: Int(self.recordingDuration),
            audioURL: audioURL,
            tags: tagTexts,
            imageURL: imageURL
        )
        
        
        FirebaseService.shared.saveRecording(recording) { [weak self] result in
            guard let self = self else { return }
            self.hideLoading()
            
            switch result {
            case .success(let recordingID):
                print("Recording saved successfully with ID: \(recordingID)")
                // Post notification to update home view
                NotificationCenter.default.post(name: Notification.Name("RecordingAdded"), object: nil)
                
                // Ana ekrana dönmeden önce başarı göstergesini göster
                self.showSuccessIndicator(message: "Saved")
                
                // Kısa bir gecikme ile ekrandan çık (göstergeyi görebilmek için)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.dismiss(animated: true)
                }
                
            case .failure(let error):
                print("Failed to save recording: \(error.localizedDescription)")
                self.showAlert(title: "Save Failed", message: "Could not save recording details. Please try again.")
            }
        }
    }
    
    private func shareRecording() {
        // Implementation for sharing the recording
        let items: [Any] = [transcriptionTextView.text ?? ""]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    private func changeTemplate() {
        let recordSettingsVC = RecordSettingsViewController()
        recordSettingsVC.modalPresentationStyle = .fullScreen
        present(recordSettingsVC, animated: true)
    }
    
    private func deleteRecording() {
        guard let recording = recording else { return }

        // Show delete confirmation alert
        let alert = UIAlertController(title: "Would you like to delete this record?", message: "This action cannot be undone.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }

            // Show loading indicator
//            self.showSuccessIndicator(message: "Deleted")

            // Delete from Firebase
            FirebaseService.shared.deleteRecording(recording) { result in
                DispatchQueue.main.async {
                    self.hideLoading()

                    switch result {
                    case .success:
                        // Show success indicator and then dismiss
                        self.showSuccessIndicator(message: "Deleted")

                        // Wait for animation to complete before dismissing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            // If we're in a navigation controller, pop
                            if let navigationController = self.navigationController {
                                navigationController.popViewController(animated: true)
                            } else {
                                // Otherwise dismiss
                                self.dismiss(animated: true)
                            }
                        }

                    case .failure(let error):
                        // Show error alert
                        self.showAlert(title: "Delete Failed", message: "Could not delete recording: \(error.localizedDescription)")
                    }
                }
            }
        }))

        present(alert, animated: true)
    }
    
    private func deleteRecordingFromMenu() {
        let alert = UIAlertController(title: "Would you like to delete this record?", message: "This action cannot be undone.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            
            // Show success indicator
            self.showSuccessIndicator(message: "Deleted")
            
            // Wait for animation to complete before dismissing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // If we're in a navigation controller, pop
                if let navigationController = self.navigationController {
                    navigationController.popViewController(animated: true)
                } else {
                    // Otherwise dismiss
                    self.dismiss(animated: true)
                }
            }
        }))
        
        present(alert, animated: true)
    }
    
//    internal func setSelectedImage(_ image: UIImage) {
//        selectedImage = image
//        selectedImageView.image = image
//        selectedImageView.isHidden = false
//        
//        // Show delete button only for new recordings
//        deleteImageButton.isHidden = recording != nil
//    }
} 
