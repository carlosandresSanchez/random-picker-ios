import Foundation

/// The rules of a draw: which numbers are in play and the order they were picked in.
struct DrawState: Equatable {
    static let countRange = 2...100

    private(set) var count: Int
    private(set) var picked: [Int] = []

    init(count: Int) {
        self.count = Self.clamped(count)
    }

    /// Numbers still in the draw: 1...count minus the ones already picked.
    var remaining: [Int] {
        (1...count).filter { !picked.contains($0) }
    }

    var canDraw: Bool { remaining.count >= 2 }
    var isLastDraw: Bool { remaining.count == 2 }
    var isFinished: Bool { remaining.isEmpty }

    static func clamped(_ count: Int) -> Int {
        min(max(count, countRange.lowerBound), countRange.upperBound)
    }

    /// Changing the number of participants starts a new draw.
    mutating func setCount(_ newCount: Int) {
        let newCount = Self.clamped(newCount)
        guard newCount != count else { return }
        count = newCount
        picked = []
    }

    /// Takes the winner out of the draw, adding it to the picked order.
    mutating func record(_ winner: Int) {
        guard remaining.contains(winner) else { return }
        picked.append(winner)
        // With one number left there is nothing to draw, so it takes the last place.
        if remaining.count == 1 { picked.append(contentsOf: remaining) }
    }

    mutating func reset() {
        picked = []
    }

    /// Picks a winner among the remaining numbers and the wheel rotation that lands on it.
    func planSpin<G: RandomNumberGenerator>(from rotation: Double, using rng: inout G) -> SpinPlan? {
        let numbers = remaining
        guard numbers.count >= 2 else { return nil }
        let index = Int.random(in: 0..<numbers.count, using: &rng)
        let target = SpinMath.targetRotation(
            current: rotation,
            winnerIndex: index,
            sliceCount: numbers.count,
            turns: Int.random(in: 5...7, using: &rng),
            // Random landing spot inside the winning slice, away from its edges.
            offsetFraction: Double.random(in: 0.15...0.85, using: &rng)
        )
        return SpinPlan(winner: numbers[index], targetRotation: target)
    }
}

struct SpinPlan: Equatable {
    let winner: Int
    let targetRotation: Double
}
