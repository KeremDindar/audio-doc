class PaywallVC: UIViewController {
    // Add scroll view
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    // Add content view for scroll view
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private func setupUI() {
        view.backgroundColor = .white
        
        // Add scroll view and content view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add all subviews to content view instead of main view
        contentView.addSubview(closeButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(featuresStackView)
        contentView.addSubview(pricingStackView)
        
        // Keep these on main view for fixed positioning
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
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(continueButton.snp.top).offset(-20)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
            make.height.greaterThanOrEqualTo(scrollView)
        }
        
        // Update existing constraints to use contentView instead of view
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(16)
            make.trailing.equalTo(contentView).offset(-16)
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(20)
            make.leading.equalTo(contentView).offset(20)
            make.trailing.equalTo(contentView).offset(-20)
        }
        
        featuresStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(60)
            make.leading.equalTo(contentView).offset(30)
            make.trailing.equalTo(contentView).offset(-30)
        }
        
        pricingStackView.snp.makeConstraints { make in
            make.top.equalTo(featuresStackView.snp.bottom).offset(40)
            make.leading.equalTo(contentView).offset(20)
            make.trailing.equalTo(contentView).offset(-20)
            make.bottom.equalTo(contentView).offset(-20) // Add bottom constraint
        }
        
        // Keep these constraints for bottom elements
        continueButton.snp.makeConstraints { make in
            make.bottom.equalTo(footerStackView.snp.top).offset(-20)
            make.leading.equalTo(view).offset(20)
            make.trailing.equalTo(view).offset(-20)
            make.height.equalTo(50)
        }
        
        footerStackView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.centerX.equalTo(view)
            make.leading.greaterThanOrEqualTo(view).offset(20)
            make.trailing.lessThanOrEqualTo(view).offset(-20)
        }
    }
    
    // ... existing code ...
} 