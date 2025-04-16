import UIKit
import SnapKit
import NeonSDK

// MARK: - UI Setup Extension
extension TranscriptionViewController {
    
    internal func setupUI() {
        view.backgroundColor = .white
        navigationController?.isNavigationBarHidden = true
        modalPresentationStyle = .fullScreen
        
        setupViewHierarchy()
        setupConstraints()
        setupGestureRecognizers()
        
        loadingContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = loadingContainer.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingContainer.insertSubview(blurView, at: 0)
        
        loadingIndicator.style = .large
        loadingIndicator.color = .white
        
        loadingLabel.textColor = .white
        loadingLabel.font = .systemFont(ofSize: 18, weight: .medium)
        loadingLabel.textAlignment = .center
        loadingLabel.numberOfLines = 0
    }
    
    private func setupViewHierarchy() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(moreButton)
        view.addSubview(dateLabel)
        view.addSubview(durationLabel)
        view.addSubview(summaryLabel)
        view.addSubview(keywordsLabel)
        view.addSubview(profileImageView)
        view.addSubview(usernameLabel)
        view.addSubview(transcriptionTextView)
        view.addSubview(selectedImageView)
        view.addSubview(deleteImageButton)
        view.addSubview(tagsScrollView)
        tagsScrollView.addSubview(tagsStackView)
        view.addSubview(audioControlsView)
        
        audioControlsView.addSubview(currentTimeLabel)
        audioControlsView.addSubview(totalTimeLabel)
        audioControlsView.addSubview(progressSlider)
        audioControlsView.addSubview(backwardButton)
        audioControlsView.addSubview(playButton)
        audioControlsView.addSubview(forwardButton)
        audioControlsView.addSubview(speedButton)
        audioControlsView.addSubview(galleryButton)
        
        // Add tag input elements
        view.addSubview(tagInputContainerView)
        tagInputContainerView.addSubview(tagInputView)
        tagInputView.addSubview(tagInputTextField)
        tagInputView.addSubview(tagInputAddButton)
        
        // Add loading view
        view.addSubview(loadingContainer)
        loadingContainer.addSubview(loadingIndicator)
        loadingContainer.addSubview(loadingLabel)
    }
    
    private func setupConstraints() {
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(30)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.centerX.equalToSuperview()
        }
        
        moreButton.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(30)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.centerY.equalTo(dateLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        summaryLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        keywordsLabel.snp.makeConstraints { make in
            make.top.equalTo(summaryLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        profileImageView.snp.makeConstraints { make in
            make.top.equalTo(keywordsLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(50)
        }
        
        usernameLabel.snp.makeConstraints { make in
            make.centerY.equalTo(profileImageView)
            make.leading.equalTo(profileImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        transcriptionTextView.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        selectedImageView.snp.makeConstraints { make in
            make.top.equalTo(transcriptionTextView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(0)
        }
        
        deleteImageButton.snp.makeConstraints { make in
            make.top.equalTo(selectedImageView).offset(8)
            make.trailing.equalTo(selectedImageView).offset(-8)
            make.width.height.equalTo(30)
        }
        
        tagsScrollView.snp.makeConstraints { make in
            make.top.equalTo(transcriptionTextView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(40)
            make.bottom.lessThanOrEqualTo(audioControlsView.snp.top).offset(-16).priority(.high)
        }
        
        tagsStackView.snp.makeConstraints { make in
            make.edges.equalTo(tagsScrollView.contentLayoutGuide)
            make.height.equalTo(tagsScrollView.frameLayoutGuide)
        }
        
        audioControlsView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(120)
        }
        
        currentTimeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalTo(progressSlider.snp.top).offset(-4)
        }
        
        totalTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(progressSlider.snp.top).offset(-4)
        }
        
        progressSlider.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(playButton.snp.top).offset(-16)
        }
        
        let buttonSize: CGFloat = 30
        let spacing: CGFloat = 32

        backwardButton.snp.makeConstraints { make in
            make.width.height.equalTo(buttonSize)
            make.centerY.equalTo(playButton)
            make.trailing.equalTo(playButton.snp.leading).offset(-spacing)
        }

        playButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }

        forwardButton.snp.makeConstraints { make in
            make.width.height.equalTo(buttonSize)
            make.centerY.equalTo(playButton)
            make.leading.equalTo(playButton.snp.trailing).offset(spacing)
        }

        speedButton.snp.makeConstraints { make in
            make.centerY.equalTo(playButton)
            make.leading.equalToSuperview().offset(16)
        }

        galleryButton.snp.makeConstraints { make in
            make.centerY.equalTo(playButton)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        tagInputContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        tagInputView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(280)
            make.height.equalTo(150)
        }
        
        tagInputTextField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(25)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
        
        tagInputAddButton.snp.makeConstraints { make in
            make.top.equalTo(tagInputTextField.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(40)
        }
        
        loadingContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.centerX.equalTo(loadingContainer)
            make.centerY.equalTo(loadingContainer).offset(-20)
            make.width.height.equalTo(50)
        }
        
        loadingLabel.snp.makeConstraints { make in
            make.centerX.equalTo(loadingContainer)
            make.top.equalTo(loadingIndicator.snp.bottom).offset(20)
            make.width.lessThanOrEqualTo(280)
        }
    }
    
    private func setupGestureRecognizers() {
        let tagInputTapGesture = UITapGestureRecognizer(target: self, action: #selector(tagInputViewTapped))
        tagInputView.addGestureRecognizer(tagInputTapGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutsideTagInput))
        tagInputContainerView.addGestureRecognizer(tapGesture)
    }
    
    // UI Helper Methods
    internal func showLoading(message: String) {
        loadingLabel.text = message
        loadingLabel.alpha = 1.0
        loadingContainer.alpha = 1.0
        loadingContainer.isHidden = false
        loadingIndicator.startAnimating()
        
        view.bringSubviewToFront(loadingContainer)
    }
    
    internal func hideLoading() {
        UIView.animate(withDuration: 0.3, animations: {
            self.loadingContainer.alpha = 0.0
            self.loadingLabel.alpha = 0.0
        }) { _ in
            self.loadingContainer.isHidden = true
            self.loadingIndicator.stopAnimating()
        }
    }
    
    internal func setSelectedImage(_ image: UIImage) {
        selectedImage = image
        selectedImageView.image = image
        selectedImageView.isHidden = false
        deleteImageButton.isHidden = false
        
        deleteImageButton.isHidden = recording != nil

        
        selectedImageView.snp.updateConstraints { make in
            make.height.equalTo(200)
        }
        
        selectedImageView.snp.remakeConstraints { make in
            make.top.equalTo(transcriptionTextView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(200)
        }
        
        tagsScrollView.snp.remakeConstraints { make in
            make.top.equalTo(selectedImageView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(40)
            make.bottom.lessThanOrEqualTo(audioControlsView.snp.top).offset(-16).priority(.high)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .layoutSubviews) {
            self.view.layoutIfNeeded()
        }
    }
    
    internal func removeSelectedImage() {
        selectedImage = nil
        selectedImageView.image = nil
        selectedImageView.isHidden = true
        deleteImageButton.isHidden = true
        
        selectedImageView.snp.remakeConstraints { make in
            make.top.equalTo(transcriptionTextView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(0)
        }
        
        tagsScrollView.snp.remakeConstraints { make in
            make.top.equalTo(transcriptionTextView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(40)
            make.bottom.lessThanOrEqualTo(audioControlsView.snp.top).offset(-16).priority(.high)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .layoutSubviews) {
            self.view.layoutIfNeeded()
        }
    }
    
    internal func showSuccessIndicator(message: String) {
        let blurView = NeonBlurView()
        blurView.colorTint = .black
        blurView.colorTintAlpha = 0.2
        blurView.blurRadius = 10
        blurView.scale = 1
        blurView.alpha = 0
        view.addSubview(blurView)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: "checkmark"))
        imageView.tintColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        blurView.contentView.addSubview(stackView)
        
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.center.equalTo(blurView.contentView)
        }
        
        UIView.animate(withDuration: 0.4, animations: {
            blurView.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                UIView.animate(withDuration: 0.2, animations: {
                    blurView.alpha = 0
                }) { _ in
                    blurView.removeFromSuperview()
                }
            }
        }
    }
    
    internal func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 16)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0
//        let padding: CGFloat = 16
        view.addSubview(toastLabel)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            toastLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            toastLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0
            }, completion: { _ in
                toastLabel.removeFromSuperview()
            })
        })
    }
    
    internal func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
} 
