import Foundation

/// Angle math for a wheel whose slice 0 starts at the top and runs clockwise, under a pointer at the top.
enum SpinMath {
    /// Clockwise rotation, in degrees, that adds `turns` full spins to `current` and stops with the
    /// pointer `offsetFraction` (0...1) of the way through slice `winnerIndex`.
    static func targetRotation(
        current: Double,
        winnerIndex: Int,
        sliceCount: Int,
        turns: Int,
        offsetFraction: Double
    ) -> Double {
        let slice = 360.0 / Double(sliceCount)
        let landing = (Double(winnerIndex) + offsetFraction) * slice
        // Rotating the wheel clockwise by R puts wheel angle (360 - R) under the pointer.
        let targetMod = (360 - landing).truncatingRemainder(dividingBy: 360)
        let currentBase = current - current.truncatingRemainder(dividingBy: 360)
        return currentBase + Double(turns) * 360 + targetMod
    }

    /// The slice under the pointer after rotating the wheel clockwise by `rotation` degrees.
    static func sliceUnderPointer(rotation: Double, sliceCount: Int) -> Int {
        var angle = (360 - rotation.truncatingRemainder(dividingBy: 360)).truncatingRemainder(dividingBy: 360)
        if angle < 0 { angle += 360 }
        return Int(angle / (360.0 / Double(sliceCount))) % sliceCount
    }
}
