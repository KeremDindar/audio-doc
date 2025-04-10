import UIKit
import SnapKit

// MARK: - AudioControlsDelegate
// Ses kontrol arayüzü için delegate protokolü
// Neden protokol kullanıldı?
// - Esnek ve genişletilebilir yapı
// - Bağımlılıkları azaltma
// - Test edilebilirlik
// Alternatif: Closure kullanılabilirdi ama bu durumda kod organizasyonu zorlaşabilirdi
protocol AudioControlsDelegate: AnyObject {
    func playButtonTapped()
    func backwardButtonTapped()
    func forwardButtonTapped()
    func speedButtonTapped()
    func galleryButtonTapped()
}

// MARK: - AudioControlsView
// Ses kontrol arayüzü için özel view
// Neden UIView'dan türetildi?
// - Özel UI bileşenleri için
// - Yeniden kullanılabilirlik
// - Kolay özelleştirme
// Alternatif: UIControl kullanılabilirdi ama bu durumda daha fazla özelleştirme gerekirdi
class AudioControlsView: UIView {
    // MARK: - Properties
    // Delegate referansı
    weak var delegate: AudioControlsDelegate?
    
    // MARK: - UI Components
    // Zaman çubuğu
    // Neden UISlider kullanıldı?
    // - Yerleşik dokunma desteği
    // - Kolay özelleştirme
    // - Performanslı
    private(set) var timeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .systemGray3
        slider.setThumbImage(UIImage(systemName: "circle.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal), for: .normal)
        return slider
    }()
    
    // Mevcut zaman etiketi
    private(set) var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .darkGray
        label.textAlignment = .left
        return label
    }()
    
    // Toplam zaman etiketi
    private(set) var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .darkGray
        label.textAlignment = .right
        return label
    }()
    
    // Geri sarma butonu
    private lazy var backwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gobackward.5"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(handleBackwardButton), for: .touchUpInside)
        return button
    }()
    
    // Oynat/Duraklat butonu
    private(set) var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(handlePlayButton), for: .touchUpInside)
        return button
    }()
    
    // İleri sarma butonu
    private lazy var forwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "goforward.5"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(handleForwardButton), for: .touchUpInside)
        return button
    }()
    
    // Hız butonu
    private(set) var speedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("1x", for: .normal)
        button.tintColor = .darkGray
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(handleSpeedButton), for: .touchUpInside)
        return button
    }()
    
    // Galeri butonu
    private lazy var galleryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "photo"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(handleGalleryButton), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    // View'ı ayarlama
    private func setupView() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 20
        
        // Kontrolleri ekle
        addSubview(timeSlider)
        addSubview(currentTimeLabel)
        addSubview(totalTimeLabel)
        
        // Kontrol butonları için stack view
        let controlsStackView = UIStackView(arrangedSubviews: [backwardButton, playButton, forwardButton])
        controlsStackView.axis = .horizontal
        controlsStackView.distribution = .equalSpacing
        controlsStackView.spacing = 40
        addSubview(controlsStackView)
        
        addSubview(speedButton)
        addSubview(galleryButton)
        
        // Layout constraints
        timeSlider.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        currentTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(timeSlider.snp.bottom).offset(5)
            make.leading.equalTo(timeSlider)
        }
        
        totalTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(timeSlider.snp.bottom).offset(5)
            make.trailing.equalTo(timeSlider)
        }
        
        controlsStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
        
        speedButton.snp.makeConstraints { make in
            make.centerY.equalTo(controlsStackView)
            make.leading.equalToSuperview().offset(20)
        }
        
        galleryButton.snp.makeConstraints { make in
            make.centerY.equalTo(controlsStackView)
            make.trailing.equalToSuperview().offset(-20)
        }
    }
    
    // MARK: - Public Methods
    // Zaman çubuğu aksiyonlarını ayarlama
    func setTimeSliderActions(valueChanged: Selector, touchDown: Selector, touchUp: Selector, target: Any) {
        timeSlider.addTarget(target, action: valueChanged, for: .valueChanged)
        timeSlider.addTarget(target, action: touchDown, for: .touchDown)
        timeSlider.addTarget(target, action: touchUp, for: [.touchUpInside, .touchUpOutside])
    }
    
    // MARK: - Button Actions
    // Oynat/Duraklat butonu aksiyonu
    @objc private func handlePlayButton() {
        delegate?.playButtonTapped()
    }
    
    // Geri sarma butonu aksiyonu
    @objc private func handleBackwardButton() {
        delegate?.backwardButtonTapped()
    }
    
    // İleri sarma butonu aksiyonu
    @objc private func handleForwardButton() {
        delegate?.forwardButtonTapped()
    }
    
    // Hız butonu aksiyonu
    @objc private func handleSpeedButton() {
        delegate?.speedButtonTapped()
    }
    
    // Galeri butonu aksiyonu
    @objc private func handleGalleryButton() {
        delegate?.galleryButtonTapped()
    }
} 
