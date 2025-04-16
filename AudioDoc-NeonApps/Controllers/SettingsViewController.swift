//
//  SettingsViewController.swift
//  AudioDoc-NeonApps
//
//  Created by Kerem on 2.04.2025.
//

import UIKit
import SnapKit

class SettingsViewController: UIViewController {
    
    // MARK: - UI Elements
    private lazy var gradientView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Settings"
        label.textColor = .white
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var premiumCard: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private lazy var diamondImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "diamond")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemPurple
        return imageView
    }()
    
    private lazy var premiumTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Get Premium"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private lazy var premiumDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Gain comprehensive access by upgrading to a premium subscription!"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .lightGray
        return imageView
    }()
    
    private lazy var menuItemsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        setupGradientBackground()
        addTitleLabel()
        setupPremiumCard()
        
        addMenuItem(icon: "star.fill", title: "Rate Us")
        addMenuItem(icon: "envelope.fill", title: "Contact Us")
        addMenuItem(icon: "lock.shield.fill", title: "Privacy Policy")
        addMenuItem(icon: "doc.text.fill", title: "Terms of Use")
        addMenuItem(icon: "arrow.counterclockwise", title: "Restore Purchase")
        addMenuItem(icon: "rectangle.portrait.and.arrow.right", title: "Logout", showChevron: false)
        
        setupConstraints()
    }
    
    private func setupGradientBackground() {
        view.addSubview(gradientView)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.4, green: 0.4, blue: 0.95, alpha: 1.0).cgColor,
            UIColor(red: 0.3, green: 0.3, blue: 0.8, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        DispatchQueue.main.async {
            gradientLayer.frame = self.gradientView.bounds
        }
    }
    
    private func addTitleLabel() {
        view.addSubview(titleLabel)
        view.bringSubviewToFront(titleLabel)
    }
    
    private func setupPremiumCard() {
        view.addSubview(premiumCard)
        view.addSubview(menuItemsStackView)
        
        premiumCard.addSubview(diamondImageView)
        premiumCard.addSubview(premiumTitleLabel)
        premiumCard.addSubview(premiumDescriptionLabel)
        premiumCard.addSubview(chevronImageView)
        
        let premiumTapGesture = UITapGestureRecognizer(target: self, action: #selector(premiumCardTapped))
        premiumCard.addGestureRecognizer(premiumTapGesture)
        premiumCard.isUserInteractionEnabled = true
    }
    
    private func setupConstraints() {
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
        }
        
        gradientView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(272)
        }
        
     

        premiumCard.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(gradientView.snp.bottom).offset(-15)
            make.height.equalTo(100)
        }
        
        premiumTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(35)
        }
        
        diamondImageView.snp.makeConstraints { make in
            make.centerY.equalTo(premiumTitleLabel)
            make.trailing.equalTo(premiumTitleLabel.snp.leading)
            make.width.height.equalTo(24)
        }
        
        premiumDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(premiumTitleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(12)
            make.height.equalTo(20)
        }
        
        menuItemsStackView.snp.makeConstraints { make in
            make.top.equalTo(gradientView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
    }
    
    private func addMenuItem(icon: String, title: String, showChevron: Bool = true) {
        let menuItemView = UIView()
        menuItemView.backgroundColor = .white
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = title == "Logout" ? .systemRed : .darkGray
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = title == "Logout" ? .systemRed : .black
        
        menuItemView.addSubview(iconImageView)
        menuItemView.addSubview(titleLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.width.height.equalTo(24)
        }
        
        if showChevron {
            let chevronImageView = UIImageView()
            chevronImageView.image = UIImage(systemName: "chevron.right")
            chevronImageView.contentMode = .scaleAspectFit
            chevronImageView.tintColor = .lightGray
            
            menuItemView.addSubview(chevronImageView)
            
            chevronImageView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-20)
                make.width.equalTo(12)
                make.height.equalTo(20)
            }
            
            titleLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalTo(iconImageView.snp.trailing).offset(16)
                make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-8)
            }
        } else {
            titleLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalTo(iconImageView.snp.trailing).offset(16)
                make.trailing.lessThanOrEqualToSuperview().offset(-20)
            }
        }
        
        menuItemsStackView.addArrangedSubview(menuItemView)
        
        menuItemView.snp.makeConstraints { make in
            make.height.equalTo(69)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(menuItemTapped(_:)))
        menuItemView.addGestureRecognizer(tapGesture)
        menuItemView.isUserInteractionEnabled = true
        menuItemView.tag = menuItemsStackView.arrangedSubviews.count - 1
    }
    
    // MARK: - Actions
    @objc private func premiumCardTapped() {
        print("Premium card tapped")
    }
    
    @objc private func menuItemTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view, let index = menuItemsStackView.arrangedSubviews.firstIndex(of: view) else {
            return
        }
        
        switch index {
        case 0:
            // Rate Us
            print("Rate Us tapped")
           
        case 1:
            // Contact Us
            print("Contact Us tapped")
        case 2:
            // Privacy Policy
            print("Privacy Policy tapped")
        case 3:
            // Terms of Use
            print("Terms of Use tapped")
        case 4:
            // Restore Purchase
            print("Restore Purchase tapped")
        case 5:
            // Logout
            print("Logout tapped")
            let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
                print("User confirmed logout")
            }))
            
            present(alert, animated: true)
        default:
            break
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradientLayer = gradientView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = gradientView.bounds
        }
    }
}
