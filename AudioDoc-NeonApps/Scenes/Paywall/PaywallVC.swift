//
//  PaywallVC.swift
//  AudioDoc-NeonApps
//
//  Created by Kerem on 27.03.2025.
//

import UIKit
import SnapKit

// MARK: - PaywallVC
class PaywallVC: UIViewController {
    
    // MARK: - UI Components
    
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "What are your\nPremium Features?"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .button
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.05, green: 0.36, blue: 0.85, alpha: 1.0).cgColor,
            UIColor(red: 0.45, green: 0.35, blue: 0.95, alpha: 1.0).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        return gradient
    }()
    
    private let featuresStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        return stack
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .black
        return button
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton()
        button.setTitle("Continue", for: .normal)
        button.backgroundColor = .button
        button.layer.cornerRadius = 25
        return button
    }()
    
    private let pricingStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()
    
    private let footerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 20
        stack.distribution = .equalSpacing
        return stack
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradient()
    }
    
    // MARK: - Private Methods
    
    private func updateGradient() {
        gradientLayer.frame = titleLabel.bounds
        
        UIGraphicsBeginImageContext(titleLabel.bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            if let gradientImage = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()
                
                titleLabel.textColor = UIColor(patternImage: gradientImage)
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(featuresStackView)
        view.addSubview(pricingStackView)
        view.addSubview(continueButton)
        view.addSubview(footerStackView)
        
        setupFeatures()
        setupPricing()
        setupFooter()
        setupConstraints()
        
        DispatchQueue.main.async { [weak self] in
            self?.updateGradient()
        }
    }
    
    private func setupFeatures() {
        let features = [
            ("mic", "Unlimited Recording Duration"),
            ("time", "Fast-Track Time Experience"),
            ("text", "Different Styles for Record Transcriptions"),
            ("save", "Save in Memory Seamlessly")
        ]
        
        features.forEach { imageName, text in
            let featureView = createFeatureView(imageName: imageName, text: text)
            featuresStackView.addArrangedSubview(featureView)
        }
        
        let screenHeight = UIScreen.main.bounds.height
        if screenHeight < 700 { // iPhone SE, iPhone 8 gibi küçük ekranlar için
            featuresStackView.spacing = 16
        } else {
            featuresStackView.spacing = 24
        }
    }
    
    private func createFeatureView(imageName: String, text: String) -> UIView {
        let container = UIView()
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: imageName)
        imageView.tintColor = .systemPurple
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 2 // Allow text to wrap if needed
        label.adjustsFontSizeToFitWidth = true // Adjust font size if needed
        
        container.addSubview(imageView)
        container.addSubview(label)
        
        imageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        label.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        container.snp.makeConstraints { make in
            make.height.equalTo(32)
        }
        
        return container
    }
    
    private func setupPricing() {
        let prices = [
            ("Weekly", "4.99$", false),
            ("Lifetime", "99.99$", true),
            ("Annual", "59.99$", false)
        ]
        
        prices.forEach { period, price, isPopular in
            let priceView = createPriceView(period: period, price: price, isPopular: isPopular)
            pricingStackView.addArrangedSubview(priceView)
        }
    }
    
    private func createPriceView(period: String, price: String, isPopular: Bool) -> UIView {
        let containerWrapper = UIView()
        
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 25
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray5.cgColor
        
        containerWrapper.addSubview(container)
        
        if isPopular {
            let popularLabel = UILabel()
            popularLabel.text = "Most Popular"
            popularLabel.font = .systemFont(ofSize: 12, weight: .medium)
            popularLabel.textColor = .white
            popularLabel.backgroundColor = .button
            popularLabel.textAlignment = .center
            popularLabel.layer.cornerRadius = 12
            popularLabel.clipsToBounds = true
            
            containerWrapper.addSubview(popularLabel)
            
            popularLabel.snp.makeConstraints { make in
                make.trailing.equalTo(container)
                make.bottom.equalTo(container.snp.top).offset(10)
                make.width.equalTo(100)
                make.height.equalTo(24)
            }
        }
        
        let periodLabel = UILabel()
        periodLabel.text = period
        periodLabel.font = .systemFont(ofSize: 20, weight: .bold)
        
        let priceLabel = UILabel()
        priceLabel.text = price
        priceLabel.font = .systemFont(ofSize: 20, weight: .bold)
        
        container.addSubview(periodLabel)
        container.addSubview(priceLabel)
        
        container.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(65)
        }
        
        periodLabel.snp.makeConstraints { make in
            make.leading.equalTo(container).offset(20)
            make.centerY.equalTo(container)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.trailing.equalTo(container).offset(-20)
            make.centerY.equalTo(container)
        }
        
        containerWrapper.snp.makeConstraints { make in
            make.height.equalTo(isPopular ? 70 : 70)
        }
        
        return containerWrapper
    }
    
    /// Sets up the footer buttons
    private func setupFooter() {
        let buttons = ["Terms of Use", "Restore Purchase", "Privacy Policy"]
        
        buttons.forEach { title in
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setTitleColor(.darkGray, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12)
            footerStackView.addArrangedSubview(button)
        }
    }
    
    private func setupConstraints() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalTo(view).offset(-16)
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(16)
            make.leading.equalTo(view).offset(20)
            make.trailing.equalTo(view).offset(-20)
        }
        
        featuresStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(32)
            make.leading.equalTo(view).offset(20)
            make.trailing.equalTo(view).offset(-20)
        }
        
        pricingStackView.snp.makeConstraints { make in
            make.top.equalTo(featuresStackView.snp.bottom).offset(24)
            make.leading.equalTo(view).offset(20)
            make.trailing.equalTo(view).offset(-20)
        }
        
        continueButton.snp.makeConstraints { make in
            make.bottom.equalTo(footerStackView.snp.top).offset(-16)
            make.leading.equalTo(view).offset(20)
            make.trailing.equalTo(view).offset(-20)
            make.height.equalTo(50)
        }
        
        footerStackView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.centerX.equalTo(view)
            make.leading.greaterThanOrEqualTo(view).offset(16)
            make.trailing.lessThanOrEqualTo(view).offset(-16)
        }
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Action Methods
    
    @objc private func closeButtonTapped() {
        navigateHome()
    }
    
    @objc private func continueButtonTapped() {
        navigateHome()
    }
    
    func navigateHome() {
        let homeVC = TabBarController()
        homeVC.view.backgroundColor = .white
        let nav = UINavigationController(rootViewController: homeVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}
