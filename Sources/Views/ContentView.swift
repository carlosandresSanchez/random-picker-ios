import SwiftUI

struct ContentView: View {
    enum Phase: Equatable {
        case idle
        case spinning
        case winner(Int)
    }

    private static let countKey = "count"
    private let spinDuration = 4.5

    @State private var draw: DrawState
    @State private var phase = Phase.idle
    @State private var rotation: Double = 0
    @State private var pendingSpin: Task<Void, Never>?
    @FocusState private var countFocused: Bool

    init() {
        let saved = UserDefaults.standard.object(forKey: Self.countKey) as? Int ?? 10
        _draw = State(initialValue: DrawState(count: saved))
    }

    private var isSpinning: Bool { phase == .spinning }

    /// The participant count; changes only apply between spins, and start a new draw.
    private var count: Binding<Int> {
        Binding(
            get: { draw.count },
            set: { newCount in
                guard phase == .idle, newCount != draw.count else { return }
                pendingSpin?.cancel()
                draw.setCount(newCount)
                UserDefaults.standard.set(draw.count, forKey: Self.countKey)
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CountInputView(count: count, isFocused: $countFocused)
                        .disabled(isSpinning)

                    SpinnerView(numbers: draw.remaining, rotation: rotation)
                        .frame(maxWidth: 320)
                        .padding(.horizontal, 24)
                        .onTapGesture(perform: spin)

                    SpinButton(isSpinning: isSpinning, action: spin)
                        .disabled(isSpinning || !draw.canDraw)
                        .padding(.horizontal, 24)

                    if !draw.picked.isEmpty {
                        PickedOrderView(picked: draw.picked, isFinished: draw.isFinished, onReset: reset)
                            .disabled(isSpinning)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Random Number")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
        }
        .onDisappear { pendingSpin?.cancel() }
        .overlay {
            if case .winner(let number) = phase {
                winnerCard(for: number)
            }
        }
        .sensoryFeedback(.success, trigger: phase) { _, newPhase in
            if case .winner = newPhase { return true }
            return false
        }
    }

    private func winnerCard(for number: Int) -> some View {
        WinnerView(
            number: number,
            color: WheelPalette.color(at: draw.remaining.firstIndex(of: number) ?? 0, count: draw.remaining.count),
            isLastDraw: draw.isLastDraw,
            onDismiss: { withAnimation(.spring) { phase = .idle } },
            onRemove: {
                withAnimation(.spring) {
                    draw.record(number)
                    phase = .idle
                }
            },
            onSpinAgain: spinAgain
        )
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }

    private func spin() {
        guard phase == .idle else { return }
        countFocused = false

        var rng = SystemRandomNumberGenerator()
        guard let plan = draw.planSpin(from: rotation, using: &rng) else { return }

        phase = .spinning
        withAnimation(.timingCurve(0.15, 0.85, 0.25, 1, duration: spinDuration)) {
            rotation = plan.targetRotation
        } completion: {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                phase = .winner(plan.winner)
            }
        }
    }

    private func spinAgain() {
        withAnimation(.spring) { phase = .idle }
        pendingSpin?.cancel()
        // Let the winner card fade out before the wheel starts turning.
        pendingSpin = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            spin()
        }
    }

    private func reset() {
        pendingSpin?.cancel()
        withAnimation { draw.reset() }
    }
}

#Preview {
    ContentView()
}
