import UIKit

class CalendarViewController: UIViewController {
    
    private let calendarView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        title = "Calendar"
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(calendarView)
        
        calendarView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
} 