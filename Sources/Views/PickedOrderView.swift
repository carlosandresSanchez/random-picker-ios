import SwiftUI

/// The numbers drawn so far, in the order they were picked.
struct PickedOrderView: View {
    let picked: [Int]
    let isFinished: Bool
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(isFinished ? "Final order" : "Already picked")
                    .font(.headline)
                Spacer()
                Button("Reset", action: onReset)
            }
            Text(picked.map { "#\($0)" }.joined(separator: "  →  "))
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
    }
}
