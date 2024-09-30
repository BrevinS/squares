import SwiftUI

struct SquareView: View {
    let date: Date
    let isVisible: Bool
    let blocksDropped: Bool
    let index: Int
    let totalItems: Int
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: isExpanded ? 0 : 8)
                .fill(Color.green)
                .overlay(
                    RoundedRectangle(cornerRadius: isExpanded ? 0 : 8)
                        .stroke(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255), lineWidth: isExpanded ? 0 : 5)
                )
                .frame(width: isExpanded ? 41 : 40, height: isExpanded ? 41 : 40)
                .opacity(blocksDropped && isVisible ? 1 : 0)
                .animation(
                    isVisible ? Animation.easeIn(duration: 0.15).delay(Double(totalItems - index) * 0.01) : .none,
                    value: blocksDropped
                )
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .disabled(isExpanded)
    }
}
