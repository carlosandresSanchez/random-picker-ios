import SwiftUI

/// The wheel turned by `rotation` degrees, with the fixed pointer at the top.
struct SpinnerView: View {
    let numbers: [Int]
    let rotation: Double

    var body: some View {
        ZStack(alignment: .top) {
            WheelView(numbers: numbers)
                .rotationEffect(.degrees(rotation))
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            Pointer()
                .fill(Color.primary)
                .frame(width: 28, height: 34)
                .offset(y: -10)
                .shadow(radius: 3)
        }
    }
}
