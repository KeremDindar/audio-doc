import UIKit

class RecordSettingsViewController: UIViewController {
    
    // MARK: - Properties
    private var selectedTemplate: String?
    private var selectedLanguage: String?
    private var summaryLength: Float = 0.3
    
    private let languages = [
        "Italian",
        "Spanish",
        "Chinese",
        "English",
        "French",
        "German",
        "Japanese"
    ]
    
    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Record Settings"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var summaryStyleCell: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(summaryStyleCellTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var summaryStyleLabel: UILabel = {
        let label = UILabel()
        label.text = "Summary Style"
        label.font = .systemFont(ofSize: 17)
        label.textColor = .label
        return label
    }()
    
    private lazy var summaryStyleValueLabel: UILabel = {
        let label = UILabel()
        label.text = selectedTemplate?.components(separatedBy: " ").first
        label.font = .systemFont(ofSize: 17)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var summaryStyleChevron: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .darkGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var languageCell: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(languageCellTapped))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    private lazy var languageLabel: UILabel = {
        let label = UILabel()
        label.text = "Output Language"
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private lazy var languageValueLabel: UILabel = {
        let label = UILabel()
        label.text = selectedLanguage
        label.font = .systemFont(ofSize: 17)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var languageChevron: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .darkGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var languagePickerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    private lazy var languagePicker: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var summaryLengthCell: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var summaryLengthLabel: UILabel = {
        let label = UILabel()
        label.text = "Summary Length"
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private lazy var summaryLengthSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = summaryLength
        slider.addTarget(self, action: #selector(summaryLengthChanged), for: .valueChanged)
        return slider
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Create gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.8).cgColor,
            UIColor.systemBlue.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.cornerRadius = 25
        button.layer.insertSublayer(gradientLayer, at: 0)
        
        // Store gradient layer as a property
        button.gradientLayer = gradientLayer
        
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Set initial selection to English
        if let englishIndex = languages.firstIndex(of: "English") {
            languagePicker.selectRow(englishIndex, inComponent: 0, animated: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        saveButton.gradientLayer?.frame = saveButton.bounds
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(summaryStyleCell)
        view.addSubview(languageCell)
        view.addSubview(summaryLengthCell)
        view.addSubview(saveButton)
        view.addSubview(languagePickerContainerView)
        
        summaryStyleCell.addSubview(summaryStyleLabel)
        summaryStyleCell.addSubview(summaryStyleValueLabel)
        summaryStyleCell.addSubview(summaryStyleChevron)
        
        languageCell.addSubview(languageLabel)
        languageCell.addSubview(languageValueLabel)
        languageCell.addSubview(languageChevron)
        
        summaryLengthCell.addSubview(summaryLengthLabel)
        summaryLengthCell.addSubview(summaryLengthSlider)
        
        languagePickerContainerView.addSubview(languagePicker)
        languagePickerContainerView.addSubview(doneButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.centerX.equalToSuperview()
        }
        
        backButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        summaryStyleCell.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(56)
        }
        
        summaryStyleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        summaryStyleValueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(summaryStyleChevron.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        
        summaryStyleChevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        languageCell.snp.makeConstraints { make in
            make.top.equalTo(summaryStyleCell.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(56)
        }
        
        languageLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        languageValueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(languageChevron.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        
        languageChevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        summaryLengthCell.snp.makeConstraints { make in
            make.top.equalTo(languageCell.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(80)
        }
        
        summaryLengthLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }
        
        summaryLengthSlider.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(summaryLengthLabel.snp.bottom).offset(8)
        }
        
        saveButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.centerX.equalToSuperview()
            make.width.equalTo(230)
            make.height.equalTo(50)
        }
        
        languagePickerContainerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(300)
        }
        
        doneButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        languagePicker.snp.makeConstraints { make in
            make.top.equalTo(doneButton.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func summaryStyleCellTapped() {
        if summaryStyleLabel.text == "Summary Style" {
            UIView.transition(with: summaryStyleLabel,
                            duration: 0.3,
                            options: .transitionCrossDissolve,
                            animations: {
                self.summaryStyleLabel.text = "Templates"
                self.summaryStyleValueLabel.isHidden = true
            })
        } else {
            let templatesVC = TemplatesViewController()
            templatesVC.delegate = self
            templatesVC.modalPresentationStyle = .fullScreen
            self.present(templatesVC, animated: true)
        }
    }
    
    @objc private func languageCellTapped() {
        languagePickerContainerView.isHidden = false
    }
    
    @objc private func doneButtonTapped() {
        languagePickerContainerView.isHidden = true
        let selectedIndex = languagePicker.selectedRow(inComponent: 0)
        selectedLanguage = languages[selectedIndex]
        languageValueLabel.text = selectedLanguage
    }
    
    @objc private func summaryLengthChanged(_ slider: UISlider) {
        summaryLength = slider.value
    }
    
    @objc private func saveButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - Template Selection Delegate
extension RecordSettingsViewController: TemplateSelectionDelegate {
    func didSelectTemplate(_ template: String) {
        selectedTemplate = template
        UIView.transition(with: summaryStyleLabel,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
            self.summaryStyleLabel.text = "Summary Style"
            self.summaryStyleValueLabel.text = template.components(separatedBy: " ").first
            self.summaryStyleValueLabel.isHidden = false
        })
    }
}

// MARK: - UIPickerView Delegate & DataSource
extension RecordSettingsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languages.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languages[row]
    }
}

protocol TemplateSelectionDelegate: AnyObject {
    func didSelectTemplate(_ template: String)
}

protocol LanguageSelectionDelegate: AnyObject {
    func didSelectLanguage(_ language: String)
}

extension UIButton {
    private struct AssociatedKeys {
        static var gradientLayer = "gradientLayer"
    }
    
    var gradientLayer: CAGradientLayer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.gradientLayer) as? CAGradientLayer
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.gradientLayer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
    }
} 

