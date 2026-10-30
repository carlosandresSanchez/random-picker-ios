import SwiftUI

@main
struct RandomPickerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

let countRange = 2...100

let wheelColors: [Color] = [
    Color(red: 0.95, green: 0.33, blue: 0.36),
    Color(red: 0.98, green: 0.62, blue: 0.24),
    Color(red: 0.98, green: 0.82, blue: 0.27),
    Color(red: 0.35, green: 0.78, blue: 0.47),
    Color(red: 0.24, green: 0.68, blue: 0.86),
    Color(red: 0.40, green: 0.45, blue: 0.92),
    Color(red: 0.69, green: 0.40, blue: 0.90),
    Color(red: 0.94, green: 0.42, blue: 0.70),
]

func colorFor(_ index: Int, count: Int) -> Color {
    // Avoid the last slice matching the first when wrapping around the palette.
    var i = index % wheelColors.count
    if index == count - 1, count > 1, i == 0 { i = 3 }
    return wheelColors[i]
}

// MARK: - Main screen

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

// MARK: - Wheel

struct WheelView: View {
    let numbers: [Int]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let count = max(numbers.count, 1)
            let slice = 360.0 / Double(count)

            ZStack {
                if numbers.isEmpty {
                    Circle().fill(Color(.tertiarySystemFill))
                }
                ForEach(Array(numbers.enumerated()), id: \.element) { index, number in
                    let start = -90 + Double(index) * slice
                    Slice(start: .degrees(start), end: .degrees(start + slice))
                        .fill(colorFor(index, count: numbers.count))
                    Slice(start: .degrees(start), end: .degrees(start + slice))
                        .stroke(.white.opacity(0.9), lineWidth: count > 40 ? 0.5 : 2)

                    Text("\(number)")
                        .font(.system(size: labelSize(count: count, radius: radius), weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                        .lineLimit(1)
                        .fixedSize()
                        // Top of the digit faces the rim, so it reads upright when under the pointer.
                        .offset(y: -radius * 0.76)
                        .rotationEffect(.degrees(start + slice / 2 + 90))
                }

                Circle()
                    .stroke(.white, lineWidth: 6)
                Circle()
                    .fill(.white)
                    .frame(width: radius * 0.22)
                    .shadow(radius: 2)
                Image(systemName: "star.fill")
                    .font(.system(size: radius * 0.1))
                    .foregroundStyle(.orange)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func labelSize(count: Int, radius: CGFloat) -> CGFloat {
        // Shrink labels so they fit in the slice's arc length near the rim.
        let arc = 2 * .pi * radius * 0.85 / CGFloat(count)
        return min(radius * 0.16, arc * 0.8)
    }
}

struct Slice: Shape {
    let start: Angle
    let end: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct Pointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Winner

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

struct ConfettiView: View {
    private struct Piece {
        let x: Double
        let delay: Double
        let speed: Double
        let spin: Double
        let drift: Double
        let size: CGSize
        let color: Color
    }

    private let pieces: [Piece] = (0..<90).map { _ in
        Piece(
            x: .random(in: 0...1),
            delay: .random(in: 0...0.8),
            speed: .random(in: 0.35...0.7),
            spin: .random(in: -6...6),
            drift: .random(in: -40...40),
            size: CGSize(width: .random(in: 6...11), height: .random(in: 10...16)),
            color: wheelColors.randomElement()!
        )
    }

    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(start)
                for piece in pieces {
                    let elapsed = t - piece.delay
                    guard elapsed > 0 else { continue }
                    let y = -20 + elapsed * piece.speed * size.height
                    guard y < size.height + 20 else { continue }
                    let x = piece.x * size.width + sin(elapsed * 3 + piece.spin) * piece.drift
                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(elapsed * piece.spin))
                    let rect = CGRect(origin: CGPoint(x: -piece.size.width / 2, y: -piece.size.height / 2), size: piece.size)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(piece.color))
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
