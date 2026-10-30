import SwiftUI

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
