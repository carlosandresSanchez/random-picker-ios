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
    /// What the count field shows; it can be out of range while the user is typing.
    @State private var typedCount: Int
    @State private var rotation: Double = 0
    @State private var pendingSpin: Task<Void, Never>?
    @FocusState private var fieldFocused: Bool

    init() {
        let saved = UserDefaults.standard.object(forKey: Self.countKey) as? Int ?? 10
        let draw = DrawState(count: saved)
        _draw = State(initialValue: draw)
        _typedCount = State(initialValue: draw.count)
    }

    private var isSpinning: Bool { phase == .spinning }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    countInput
                    wheel
                    spinButton
                    pickedSection
                }
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Random Number")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { fieldFocused = false }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .onChange(of: typedCount) {
            // Clamp the top right away; the bottom waits until typing ends so "15" can pass through "1".
            if typedCount > DrawState.countRange.upperBound { typedCount = DrawState.countRange.upperBound }
            if DrawState.countRange.contains(typedCount) { applyCount(typedCount) }
        }
        .onChange(of: fieldFocused) {
            if !fieldFocused { commitTypedCount() }
        }
        .onDisappear { pendingSpin?.cancel() }
        .overlay {
            if case .winner(let number) = phase {
                WinnerView(
                    number: number,
                    color: WheelPalette.color(
                        at: draw.remaining.firstIndex(of: number) ?? 0,
                        count: draw.remaining.count
                    ),
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
        }
        .sensoryFeedback(.success, trigger: phase) { _, newPhase in
            if case .winner = newPhase { return true }
            return false
        }
    }

    private var countInput: some View {
        VStack(spacing: 8) {
            Text("How many participants?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                stepButton("minus", delta: -1)
                TextField("", value: $typedCount, format: .number)
                    .keyboardType(.numberPad)
                    .focused($fieldFocused)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .frame(width: 110)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
                stepButton("plus", delta: 1)
            }
            Text("Each person picks a number from 1 to \(draw.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .disabled(isSpinning)
    }

    private func stepButton(_ symbol: String, delta: Int) -> some View {
        Button {
            typedCount = DrawState.clamped(draw.count + delta)
        } label: {
            Image(systemName: symbol)
                .font(.title2.bold())
                .frame(width: 52, height: 52)
                .background(Color(.secondarySystemGroupedBackground), in: .circle)
        }
        .buttonRepeatBehavior(.enabled)
        .disabled(!DrawState.countRange.contains(draw.count + delta))
    }

    private var wheel: some View {
        ZStack(alignment: .top) {
            WheelView(numbers: draw.remaining)
                .rotationEffect(.degrees(rotation))
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            Pointer()
                .fill(Color.primary)
                .frame(width: 28, height: 34)
                .offset(y: -10)
                .shadow(radius: 3)
        }
        .frame(maxWidth: 320)
        .padding(.horizontal, 24)
        .onTapGesture { spin() }
    }

    private var spinButton: some View {
        Button(action: spin) {
            Label(isSpinning ? "Spinning…" : "Spin", systemImage: "arrow.clockwise.circle.fill")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isSpinning || !draw.canDraw)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var pickedSection: some View {
        if !draw.picked.isEmpty {
            VStack(spacing: 10) {
                HStack {
                    Text(draw.isFinished ? "Final order" : "Already picked")
                        .font(.headline)
                    Spacer()
                    Button("Reset") {
                        pendingSpin?.cancel()
                        withAnimation { draw.reset() }
                    }
                    .disabled(isSpinning)
                }
                Text(draw.picked.map { "#\($0)" }.joined(separator: "  →  "))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }

    private func applyCount(_ count: Int) {
        guard count != draw.count else { return }
        pendingSpin?.cancel()
        draw.setCount(count)
        UserDefaults.standard.set(draw.count, forKey: Self.countKey)
    }

    /// Applies whatever is in the field, raising a too-small number to the minimum.
    private func commitTypedCount() {
        applyCount(DrawState.clamped(typedCount))
        typedCount = draw.count
    }

    private func spin() {
        guard phase == .idle else { return }
        fieldFocused = false
        commitTypedCount()

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
}

#Preview {
    ContentView()
}
