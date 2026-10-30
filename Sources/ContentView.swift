import SwiftUI

let countRange = 2...100

struct ContentView: View {
    @AppStorage("count") private var count = 10
    @State private var picked: [Int] = []
    @State private var rotation: Double = 0
    @State private var isSpinning = false
    @State private var winner: Int?
    @FocusState private var fieldFocused: Bool

    private let spinDuration = 4.5

    /// Numbers still in the draw: 1...count minus the ones removed after winning.
    private var remaining: [Int] {
        (1...max(count, 1)).filter { !picked.contains($0) }
    }

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
        .onChange(of: count) {
            // Clamp the top right away; the bottom waits until typing ends so "15" can pass through "1".
            if count > countRange.upperBound { count = countRange.upperBound }
            picked = []
        }
        .onChange(of: fieldFocused) {
            if !fieldFocused, count < countRange.lowerBound { count = countRange.lowerBound }
        }
        .overlay {
            if let winner {
                WinnerView(
                    number: winner,
                    color: colorFor(remaining.firstIndex(of: winner) ?? 0, count: remaining.count),
                    isLastDraw: remaining.count == 2,
                    onDismiss: { withAnimation(.spring) { self.winner = nil } },
                    onRemove: {
                        withAnimation(.spring) {
                            picked.append(winner)
                            // With one number left there is nothing to draw, so it takes the last place.
                            if remaining.count == 1 { picked.append(contentsOf: remaining) }
                            self.winner = nil
                        }
                    },
                    onSpinAgain: {
                        withAnimation(.spring) { self.winner = nil }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { spin() }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .sensoryFeedback(.success, trigger: winner)
    }

    private var countInput: some View {
        VStack(spacing: 8) {
            Text("How many participants?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                stepButton("minus", delta: -1)
                TextField("", value: $count, format: .number)
                    .keyboardType(.numberPad)
                    .focused($fieldFocused)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .frame(width: 110)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
                stepButton("plus", delta: 1)
            }
            Text("Each person picks a number from 1 to \(count)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .disabled(isSpinning)
    }

    private func stepButton(_ symbol: String, delta: Int) -> some View {
        Button {
            count = min(max(count + delta, countRange.lowerBound), countRange.upperBound)
        } label: {
            Image(systemName: symbol)
                .font(.title2.bold())
                .frame(width: 52, height: 52)
                .background(Color(.secondarySystemGroupedBackground), in: .circle)
        }
        .buttonRepeatBehavior(.enabled)
        .disabled(count + delta < countRange.lowerBound || count + delta > countRange.upperBound)
    }

    private var wheel: some View {
        ZStack(alignment: .top) {
            WheelView(numbers: remaining)
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
        .disabled(isSpinning || remaining.count < 2)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var pickedSection: some View {
        if !picked.isEmpty {
            VStack(spacing: 10) {
                HStack {
                    Text(remaining.isEmpty ? "Final order" : "Already picked")
                        .font(.headline)
                    Spacer()
                    Button("Reset") { withAnimation { picked = [] } }
                        .disabled(isSpinning)
                }
                Text(picked.map { "#\($0)" }.joined(separator: "  →  "))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }

    private func spin() {
        let numbers = remaining
        guard !isSpinning, numbers.count >= 2 else { return }
        fieldFocused = false

        let winnerIndex = Int.random(in: 0..<numbers.count)
        let slice = 360.0 / Double(numbers.count)
        // Random landing spot inside the winning slice, away from its edges.
        let offsetInSlice = Double.random(in: slice * 0.15...slice * 0.85)
        let landing = Double(winnerIndex) * slice + offsetInSlice
        // The pointer is at the top; rotating the wheel clockwise by R puts wheel angle (360 - R) under it.
        let targetMod = (360 - landing).truncatingRemainder(dividingBy: 360)
        let currentBase = rotation - rotation.truncatingRemainder(dividingBy: 360)
        let fullTurns = Double(Int.random(in: 5...7)) * 360

        isSpinning = true
        withAnimation(.timingCurve(0.15, 0.85, 0.25, 1, duration: spinDuration)) {
            rotation = currentBase + fullTurns + targetMod
        } completion: {
            isSpinning = false
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                winner = numbers[winnerIndex]
            }
        }
    }
}

#Preview {
    ContentView()
}
