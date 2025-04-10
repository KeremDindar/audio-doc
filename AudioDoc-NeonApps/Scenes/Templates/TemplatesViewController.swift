import UIKit

class TemplatesViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: TemplateSelectionDelegate?
    
    private let templates = [
        (name: "Social media style transcribe", icon: "message.fill"),
        (name: "Essay style transcribe", icon: "doc.text.fill"),
        (name: "Poem style transcribe", icon: "text.quote"),
        (name: "Review style transcribe", icon: "star.fill"),
        (name: "Song lyrics style transcribe", icon: "music.note"),
        (name: "Memo style transcribe", icon: "note.text"),
        (name: "Letter style transcribe", icon: "envelope.fill"),
        (name: "Email style transcribe", icon: "envelope.fill"),
        (name: "Blog style transcribe", icon: "globe"),
        (name: "Business plan style transcribe", icon: "briefcase.fill"),
        (name: "Market research style transcribe", icon: "chart.bar.fill"),
        (name: "Annual style transcribe", icon: "calendar"),
        (name: "Financial statement style transcribe", icon: "dollarsign.circle.fill"),
        (name: "Proposal style transcribe", icon: "doc.fill"),
        (name: "Researcher paper style transcribe", icon: "book.fill"),
        (name: "Feasibility Study style transcribe", icon: "checkmark.circle.fill"),
        (name: "Case study style transcribe", icon: "doc.text.magnifyingglass"),
        (name: "White paper style transcribe", icon: "doc.fill"),
        (name: "Progress report style transcribe", icon: "chart.line.uptrend.xyaxis"),
        (name: "Meeting minutes style transcribe", icon: "clock.fill"),
        (name: "Policy document style transcribe", icon: "doc.text.fill"),
        (name: "User manual style transcribe", icon: "book.fill"),
        (name: "Incident report style transcribe", icon: "exclamationmark.triangle.fill"),
        (name: "Market analysis report style transcribe", icon: "chart.pie.fill"),
        (name: "Marketing plan style transcribe", icon: "megaphone.fill"),
        (name: "Project report style transcribe", icon: "folder.fill")
    ]
    
    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Templates"
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
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorStyle = .none
        return tableView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(tableView)
        
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
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension TemplatesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return templates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let template = templates[indexPath.row]
        
        // Configure cell content
        var content = cell.defaultContentConfiguration()
        content.text = template.name
        content.textProperties.color = .black
        content.image = UIImage(systemName: template.icon)
        content.imageProperties.tintColor = .black
        content.imageToTextPadding = 12
        
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectTemplate(templates[indexPath.row].name)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
} 