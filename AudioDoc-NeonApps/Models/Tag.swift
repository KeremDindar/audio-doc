import UIKit

struct Tag {
    let text: String
    let color: UIColor
    
    static func randomColor() -> UIColor {
        let colors: [UIColor] = [
            .systemBlue,
            .systemGreen,
            .systemIndigo,
            .systemOrange,
            .systemPink,
            .systemPurple,
            .systemRed,
            .systemTeal
        ]
        
        return colors.randomElement() ?? .systemBlue
    }
} 