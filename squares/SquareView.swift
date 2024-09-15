import SwiftUI

struct SquareView: View {
    let date: Date
    let isVisible: Bool
    let blocksDropped: Bool
    let index: Int
    let totalItems: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green) // Green fill
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255), lineWidth: 5) // Light grey outline
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Text("") // No number displayed on the square
                )
                .opacity(blocksDropped && isVisible ? 1 : 0)
                .animation(
                    isVisible ? Animation.easeIn(duration: 0.15).delay(Double(totalItems - index) * 0.01) : .none,
                    value: blocksDropped
                )
        }
    }
}
