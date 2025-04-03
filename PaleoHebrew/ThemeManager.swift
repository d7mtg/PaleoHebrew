import SwiftUI

struct ThemeManager {
    @AppStorage("selectedAccentColor") static var accentColor: String = "blue"
    
    static var currentAccent: Color {
        Color(accentColor)
    }
    
    static var currentUIColor: UIColor {
        UIColor(currentAccent)
    }
}
