import SwiftUI

enum WheelPalette {
    static let colors: [Color] = [
        Color(red: 0.95, green: 0.33, blue: 0.36),
        Color(red: 0.98, green: 0.62, blue: 0.24),
        Color(red: 0.98, green: 0.82, blue: 0.27),
        Color(red: 0.35, green: 0.78, blue: 0.47),
        Color(red: 0.24, green: 0.68, blue: 0.86),
        Color(red: 0.40, green: 0.45, blue: 0.92),
        Color(red: 0.69, green: 0.40, blue: 0.90),
        Color(red: 0.94, green: 0.42, blue: 0.70),
    ]

    static func color(at index: Int, count: Int) -> Color {
        // Avoid the last slice matching the first when wrapping around the palette.
        var i = index % colors.count
        if index == count - 1, count > 1, i == 0 { i = 3 }
        return colors[i]
    }
}
