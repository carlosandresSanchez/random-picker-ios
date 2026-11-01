import Testing
@testable import RandomPicker

struct SpinMathTests {
    /// The pointer must end inside the winner's slice for every wheel size the app allows.
    @Test(arguments: DrawState.countRange)
    func landsInsideTheWinningSlice(sliceCount: Int) {
        for winnerIndex in 0..<sliceCount {
            for offset in [0.15, 0.5, 0.85] {
                for current in [0.0, 123.4, 3_600.0, 98_765.4] {
                    let target = SpinMath.targetRotation(
                        current: current,
                        winnerIndex: winnerIndex,
                        sliceCount: sliceCount,
                        turns: 5,
                        offsetFraction: offset
                    )
                    #expect(SpinMath.sliceUnderPointer(rotation: target, sliceCount: sliceCount) == winnerIndex)
                }
            }
        }
    }

    /// Ties the drawing to the landing math: after the spin, the pointer must sit inside the
    /// angles where WheelView actually drew the winner's slice.
    @Test(arguments: DrawState.countRange)
    func pointerSitsInsideTheDrawnWinningSlice(sliceCount: Int) {
        for winnerIndex in 0..<sliceCount {
            for offset in [0.15, 0.5, 0.85] {
                let target = SpinMath.targetRotation(
                    current: 123.4,
                    winnerIndex: winnerIndex,
                    sliceCount: sliceCount,
                    turns: 5,
                    offsetFraction: offset
                )
                let drawn = SpinMath.sliceAngles(index: winnerIndex, sliceCount: sliceCount)
                // Rotating the wheel by `target` brings this wheel angle under the pointer.
                let pointerOnWheel = SpinMath.pointerAngle - target
                var intoSlice = (pointerOnWheel - drawn.start).truncatingRemainder(dividingBy: 360)
                if intoSlice < 0 { intoSlice += 360 }
                #expect(intoSlice > 0 && intoSlice < drawn.end - drawn.start)
            }
        }
    }

    @Test(arguments: [5, 6, 7])
    func addsAtLeastTheRequestedFullTurns(turns: Int) {
        let current = 725.0
        let target = SpinMath.targetRotation(
            current: current, winnerIndex: 0, sliceCount: 4, turns: turns, offsetFraction: 0.5
        )
        #expect(target - current >= Double(turns - 1) * 360)
        #expect(target - current < Double(turns + 1) * 360)
    }

    @Test func noRotationPutsTheFirstSliceUnderThePointer() {
        #expect(SpinMath.sliceUnderPointer(rotation: 0, sliceCount: 4) == 0)
        // Turning the wheel slightly clockwise brings the last slice under the top pointer.
        #expect(SpinMath.sliceUnderPointer(rotation: 10, sliceCount: 4) == 3)
    }
}
