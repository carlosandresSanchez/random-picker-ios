import Testing
@testable import RandomPicker

/// Deterministic generator (SplitMix64) so draws repeat exactly for a given seed.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct DrawStateTests {
    @Test func startsWithEveryNumberRemaining() {
        let draw = DrawState(count: 5)
        #expect(draw.remaining == [1, 2, 3, 4, 5])
        #expect(draw.picked.isEmpty)
        #expect(draw.canDraw)
    }

    @Test(arguments: [(-3, 2), (0, 2), (1, 2), (2, 2), (50, 50), (100, 100), (101, 100), (999, 100)])
    func clampsCountToRange(input: Int, expected: Int) {
        #expect(DrawState(count: input).count == expected)
        var draw = DrawState(count: 10)
        draw.setCount(input)
        #expect(draw.count == expected)
    }

    @Test func recordRemovesWinnerFromRemaining() {
        var draw = DrawState(count: 4)
        draw.record(3)
        #expect(draw.picked == [3])
        #expect(draw.remaining == [1, 2, 4])
        #expect(!draw.isFinished)
    }

    @Test func recordingWithTwoLeftAddsBothInOrder() {
        var draw = DrawState(count: 3)
        draw.record(2)
        #expect(draw.isLastDraw)
        draw.record(3)
        #expect(draw.picked == [2, 3, 1])
        #expect(draw.remaining.isEmpty)
        #expect(draw.isFinished)
        #expect(!draw.canDraw)
    }

    @Test func recordIgnoresNumbersNotInPlay() {
        var draw = DrawState(count: 3)
        draw.record(2)
        draw.record(2)
        draw.record(7)
        #expect(draw.picked == [2])
    }

    @Test func changingCountStartsANewDraw() {
        var draw = DrawState(count: 5)
        draw.record(1)
        draw.setCount(6)
        #expect(draw.count == 6)
        #expect(draw.picked.isEmpty)
    }

    @Test func settingTheSameCountKeepsTheDraw() {
        var draw = DrawState(count: 5)
        draw.record(1)
        draw.setCount(5)
        #expect(draw.picked == [1])
    }

    @Test func resetClearsPicked() {
        var draw = DrawState(count: 5)
        draw.record(4)
        draw.reset()
        #expect(draw.picked.isEmpty)
        #expect(draw.remaining.count == 5)
    }

    @Test func planSpinIsDeterministicForASeed() {
        let draw = DrawState(count: 10)
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        #expect(draw.planSpin(from: 0, using: &a) == draw.planSpin(from: 0, using: &b))
    }

    @Test func planSpinLandsOnItsWinnerAndNeverOnAPickedNumber() throws {
        var draw = DrawState(count: 8)
        draw.record(2)
        draw.record(5)
        var rng = SeededGenerator(seed: 7)
        var rotation = 0.0
        for _ in 0..<500 {
            let plan = try #require(draw.planSpin(from: rotation, using: &rng))
            #expect(!draw.picked.contains(plan.winner))
            #expect(plan.targetRotation > rotation)
            let slice = SpinMath.sliceUnderPointer(rotation: plan.targetRotation, sliceCount: draw.remaining.count)
            #expect(draw.remaining[slice] == plan.winner)
            rotation = plan.targetRotation
        }
    }

    @Test func planSpinCoversEveryRemainingNumber() {
        let draw = DrawState(count: 6)
        var rng = SeededGenerator(seed: 1)
        let winners = Set((0..<300).compactMap { _ in draw.planSpin(from: 0, using: &rng)?.winner })
        #expect(winners == Set(1...6))
    }

    @Test func planSpinNeedsTwoNumbers() {
        var draw = DrawState(count: 2)
        draw.record(1)
        var rng = SeededGenerator(seed: 1)
        #expect(draw.planSpin(from: 0, using: &rng) == nil)
    }
}
