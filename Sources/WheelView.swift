import SwiftUI

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
