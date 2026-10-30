import SwiftUI

struct WinnerView: View {
    let number: Int
    let color: Color
    let isLastDraw: Bool
    let onDismiss: () -> Void
    let onRemove: () -> Void
    let onSpinAgain: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 14) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.yellow.gradient)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .rotationEffect(.degrees(appeared ? 0 : -30))

                Text("The winner is number")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("\(number)")
                    .font(.system(size: 110, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                    .scaleEffect(appeared ? 1 : 0.5)

                VStack(spacing: 10) {
                    Button(action: onSpinAgain) {
                        Label("Spin again", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    HStack(spacing: 10) {
                        Button(action: onRemove) {
                            Label(isLastDraw ? "Finish" : "Remove",
                                  systemImage: isLastDraw ? "checkmark.circle" : "minus.circle")
                                .frame(maxWidth: .infinity)
                        }
                        Button(action: onDismiss) {
                            Text("Done").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
                .padding(.top, 6)
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background(.regularMaterial, in: .rect(cornerRadius: 28))
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1)) {
                appeared = true
            }
        }
    }
}
