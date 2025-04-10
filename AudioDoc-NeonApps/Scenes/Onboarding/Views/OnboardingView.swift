import UIKit
import SnapKit

class OnboardingView: UIView {
    // MARK: - UI Components
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 3
        pageControl.currentPageIndicatorTintColor = .systemBlue
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.5)
        pageControl.layer.cornerRadius = 12
        pageControl.clipsToBounds = true
        pageControl.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        pageControl.isUserInteractionEnabled = false
        return pageControl
    }()
    
    let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .button
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 4
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(scrollView)
        addSubview(pageControl)
        addSubview(nextButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(nextButton.snp.top).offset(-30)
            make.centerX.equalToSuperview()
            make.height.equalTo(30)
        }
        
        nextButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-30)
            make.leading.trailing.equalToSuperview().inset(40)
            make.height.equalTo(55)
        }
    }
    
    // MARK: - Layout Updates
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if UIScreen.main.bounds.height <= 667 {
            pageControl.snp.updateConstraints { make in
                make.bottom.equalTo(nextButton.snp.top).offset(-15)
            }
        }
    }
} 
