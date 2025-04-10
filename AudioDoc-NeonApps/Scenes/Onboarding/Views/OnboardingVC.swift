import UIKit
import SnapKit
import NeonSDK

class OnboardingViewController: UIViewController {
    // MARK: - Properties
    private let onboardingView = OnboardingView()
    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            title: "Voice to Text",
            description: "Transform the spoken word into polished text effortlessly with AudioDoc.",
            image: UIImage(named: "1")!,
            frontImage: UIImage(named: "onboarding1")!
        ),
        OnboardingSlide(
            title: "Records in Memory",
            description: "The sounds you record can be turned into meaningful text. You can add photos and customize them.",
            image: UIImage(named: "2")!,
            frontImage: UIImage(named: "onboarding2")!
        ),
        OnboardingSlide(
            title: "Make Records Easily",
            description: "All your projects are stored in memory, and you can change the text styles and regain access to them at any time.",
            image: UIImage(named: "3")!,
            frontImage: UIImage(named: "onboarding3")!
        )
    ]
    
    // MARK: - Lifecycle
    override func loadView() {
        view = onboardingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSlides()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIScreen.main.bounds.height <= 667 {
            onboardingView.pageControl.snp.updateConstraints { make in
                make.bottom.equalTo(onboardingView.nextButton.snp.top).offset(-15)
            }
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        onboardingView.scrollView.delegate = self
        onboardingView.nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    private func setupSlides() {
        var previousSlide: UIView? = nil
        
        for slide in slides {
            let slideView = OnboardingSlideView(slide: slide)
            onboardingView.scrollView.addSubview(slideView)
            
            slideView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.equalTo(view)
                make.height.equalTo(onboardingView.scrollView)
                if let previous = previousSlide {
                    make.leading.equalTo(previous.snp.trailing)
                } else {
                    make.leading.equalToSuperview()
                }
            }
            previousSlide = slideView
        }
        
        if let lastSlide = previousSlide {
            onboardingView.scrollView.snp.makeConstraints { make in
                make.trailing.equalTo(lastSlide.snp.trailing)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func nextButtonTapped() {
        if onboardingView.pageControl.currentPage == slides.count - 1 {
            Neon.activatePremiumTest()
            navigateToPaywall()
        } else {
            moveToNextPage()
        }
    }
    
    // MARK: - Navigation
    private func navigateToPaywall() {
        let homeVC = PaywallVC()
        homeVC.modalPresentationStyle = .fullScreen
        present(homeVC, animated: true)
    }
    
    private func moveToNextPage() {
        let nextPage = onboardingView.pageControl.currentPage + 1
        let xOffset = CGFloat(nextPage) * view.bounds.width
        onboardingView.scrollView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = round(scrollView.contentOffset.x / view.bounds.width)
        onboardingView.pageControl.currentPage = Int(page)
    }
}

