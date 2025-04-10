import UIKit
import SnapKit

class OnboardingSlideView: UIView {
    private let imageView = UIImageView()
    private let frontImageView = UIImageView()
    private let bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 30
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    init(slide: OnboardingSlide) {
        super.init(frame: .zero)
        
        imageView.image = slide.image
        imageView.contentMode = .scaleAspectFit
        
        frontImageView.image = slide.frontImage
        frontImageView.contentMode = .scaleAspectFit
        frontImageView.clipsToBounds = true
        
        titleLabel.text = slide.title
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Create paragraph style with line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 7 // Add 8 points of space between lines
        
        // Create attributed string with the paragraph style
        let attributedString = NSAttributedString(
            string: slide.description,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.systemFont(ofSize: 19),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        
        descriptionLabel.attributedText = attributedString
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(imageView)
        addSubview(frontImageView)
        addSubview(bottomView)
        bottomView.addSubview(titleLabel)
        bottomView.addSubview(descriptionLabel)
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
        }
        
        frontImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(120)
            make.centerX.equalToSuperview()
            make.width.equalTo(imageView.snp.width).multipliedBy(1.4)
            make.height.equalTo(imageView.snp.height).multipliedBy(1)
        }
        
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(48)
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }
} 
