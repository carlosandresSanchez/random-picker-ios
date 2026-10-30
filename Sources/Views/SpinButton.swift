import SwiftUI

struct SpinButton: View {
    let isSpinning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isSpinning ? "Spinning…" : "Spin", systemImage: "arrow.clockwise.circle.fill")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}
