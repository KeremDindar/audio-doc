import UIKit
import SnapKit
import NeonSDK

class RecordingTableViewCell: UITableViewCell {
    static let identifier = "RecordingTableViewCell"
    
    // MARK: - Properties
    private var isHomeView: Bool = false
    private var currentImageURL: String?
    private var imageLoadTask: URLSessionDataTask?
    
    // MARK: - UI Elements
    private lazy var recordingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()
    
    private let dateStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    private let durationStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    private let calendarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "calendar")?.withConfiguration(UIImage.SymbolConfiguration(weight: .medium))
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let clockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "clock.fill")?.withConfiguration(UIImage.SymbolConfiguration(weight: .medium))
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let transcriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 3
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageLoadTask = nil
        currentImageURL = nil
        recordingImageView.image = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Add subviews
        contentView.addSubview(containerView)
        containerView.addSubview(profileImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(infoStackView)
        containerView.addSubview(recordingImageView)
        containerView.addSubview(transcriptionLabel)
        
        // Setup stack views
        dateStackView.addArrangedSubview(calendarImageView)
        dateStackView.addArrangedSubview(dateLabel)
        
        durationStackView.addArrangedSubview(clockImageView)
        durationStackView.addArrangedSubview(durationLabel)
        
        infoStackView.addArrangedSubview(dateStackView)
        infoStackView.addArrangedSubview(durationStackView)
        
        // Set constraints
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(160)
        }
        
        profileImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(profileImageView)
            make.leading.equalTo(profileImageView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(infoStackView.snp.leading).offset(-8)
        }
        
        infoStackView.snp.makeConstraints { make in
            make.centerY.equalTo(profileImageView)
            make.trailing.equalToSuperview().offset(-12)
        }
        
//        recordingImageView.snp.makeConstraints { make in
//            make.top.equalTo(profileImageView.snp.bottom).offset(12)
//            make.leading.equalTo(profileImageView)
//            if isHomeView {
//                make.width.equalTo(99)
//                make.height.equalTo(77)
//            } else {
//                make.width.equalTo(55)
//                make.height.equalTo(43)
//            }
//            make.bottom.equalToSuperview().offset(-12)
//        }
        
        transcriptionLabel.snp.makeConstraints { make in
            make.centerY.equalTo(recordingImageView)
            make.leading.equalTo(recordingImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        // Set icon sizes
        calendarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        clockImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
    }
    
    // MARK: - Image Loading
    private func loadImage(from urlString: String) {
        // Cancel any existing task
        imageLoadTask?.cancel()
        
        // Store the current URL
        currentImageURL = urlString
        
        // Check cache first
        if let cachedImage = ImageCache.shared.getImage(for: urlString) {
            recordingImageView.image = cachedImage
            return
        }
        
        // Show loading state
        recordingImageView.image = UIImage(systemName: "photo.fill")?.withConfiguration(UIImage.SymbolConfiguration(weight: .light))
        recordingImageView.backgroundColor = .systemGray6
        recordingImageView.tintColor = .systemGray3
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        // Create a background task for image loading
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data),
                  self.currentImageURL == urlString else {
                return
            }
            
            ImageCache.shared.setImage(image, for: urlString)
            
            DispatchQueue.main.async {
                UIView.transition(with: self.recordingImageView,
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                    self.recordingImageView.image = image
                })
            }
        }
        
        imageLoadTask = task
        task.resume()
    }
    
    // MARK: - Configuration
    func configure(with recording: Recording, index: Int, isHomeView: Bool = false) {
        self.isHomeView = isHomeView
        
        // Update constraints based on view type
        recordingImageView.snp.remakeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(12)
            make.leading.equalTo(profileImageView)
            if isHomeView {
                make.width.equalTo(99)
                make.height.equalTo(77)
            } else {
                make.width.equalTo(55)
                make.height.equalTo(43)
            }
            make.bottom.equalToSuperview().offset(-12)
        }
        
        // Set default text for empty title
        if recording.title.isEmpty {
            titleLabel.text = "No Title"
        } else {
            titleLabel.text = recording.title
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        dateLabel.text = dateFormatter.string(from: recording.createdAt)
        
        let minutes = Int(recording.duration) / 60
        let seconds = Int(recording.duration) % 60
        durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        // Display transcription or default message when empty
        if !recording.transcription.isEmpty {
            transcriptionLabel.text = recording.transcription.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
        } else if !recording.summaryKeywords.isEmpty {
            // Show summary keywords if available
            transcriptionLabel.text = "Anahtar Kelimeler: " + recording.summaryKeywords.joined(separator: ", ")
        } else {
            // If both transcription and summary keywords are empty
            transcriptionLabel.text = "No transcription"
        }
        
        if let imageURLString = recording.imageURL, !imageURLString.isEmpty {
            recordingImageView.isHidden = false
            loadImage(from: imageURLString)
        } else {
            recordingImageView.isHidden = false
            recordingImageView.image = UIImage(systemName: "photo.fill")?.withConfiguration(UIImage.SymbolConfiguration(weight: .light))
            recordingImageView.backgroundColor = .systemGray6
            recordingImageView.tintColor = .systemGray3
        }
        
        // Update background and text colors
        containerView.backgroundColor = index % 2 == 0 ? UIColor(hex: "E0EBFF") : UIColor(hex: "F1F1F1")
        
        let textColor = index % 2 == 0 ? (UIColor(named: "ButtonColor") ?? .secondaryLabel) : .secondaryLabel
        dateLabel.textColor = textColor
        durationLabel.textColor = textColor
        calendarImageView.tintColor = textColor
        clockImageView.tintColor = textColor
    }
}

// UIColor extension for hex colors
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

// MARK: - Image Cache
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    private var memoryWarningObserver: NSObjectProtocol?
    
    private init() {
        // Set cache limits
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Observe memory warnings
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.clearCache()
            }
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func setImage(_ image: UIImage, for key: String) {
        let cost = image.size.width * image.size.height * image.scale
        cache.setObject(image, forKey: key as NSString, cost: Int(cost))
    }
    
    func getImage(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
} 
