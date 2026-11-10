import SwiftUI

struct AppTheme {
    // Primary colors
    static let accentColor = Color(hex: "#1DB954")
    static let secondaryAccent = Color(hex: "#E91E63")
    static let tertiaryAccent = Color(hex: "#FF9800")

    // Background colors
    static let backgroundColor = Color(hex: "#121212")
    static let surfaceColor = Color(hex: "#1E1E1E")
    static let cardColor = Color(hex: "#282828")
    static let elevatedColor = Color(hex: "#333333")

    // Text colors
    static let primaryText = Color.white
    static let secondaryText = Color(hex: "#B3B3B3")
    static let tertiaryText = Color(hex: "#737373")

    // Gradient presets
    static let vibrantGradient = LinearGradient(
        colors: [Color(hex: "#1DB954"), Color(hex: "#191414")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pinkGradient = LinearGradient(
        colors: [Color(hex: "#E91E63"), Color(hex: "#121212")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let purpleGradient = LinearGradient(
        colors: [Color(hex: "#9C27B0"), Color(hex: "#121212")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let orangeGradient = LinearGradient(
        colors: [Color(hex: "#FF9800"), Color(hex: "#121212")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let blueGradient = LinearGradient(
        colors: [Color(hex: "#2196F3"), Color(hex: "#121212")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let gradients: [LinearGradient] = [
        vibrantGradient, pinkGradient, purpleGradient, orangeGradient, blueGradient
    ]

    static func randomGradient() -> LinearGradient {
        gradients.randomElement() ?? vibrantGradient
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor Extension for UIKit Components
#if canImport(UIKit)
import UIKit

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}
#endif

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(AppTheme.cardColor)
            .cornerRadius(12)
    }

    func glowEffect(color: Color = AppTheme.accentColor) -> some View {
        self.shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 0)
    }
}

