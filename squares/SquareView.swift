import SwiftUI

struct SquareView: View {
    let date: Date
    let isVisible: Bool
    let blocksDropped: Bool
    let index: Int
    let totalItems: Int
    let isExpanded: Bool
    let workout: LocalWorkout?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: isExpanded ? 0 : 8)
                .fill(fillColor)
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
    
    private var fillColor: Color {
        guard let workout = workout else {
            return Color(red: 23 / 255, green: 27 / 255, blue: 33 / 255)
        }
        
        let distance = workout.distance
        if distance < 1000 {
            return Color(red: 0 / 255, green: 109 / 255, blue: 50 / 255)
        } else if distance < 5000 {
            return Color(red: 0 / 255, green: 155 / 255, blue: 71 / 255)
        } else if distance < 10000 {
            return Color(red: 0 / 255, green: 201 / 255, blue: 93 / 255)
        } else {
            return Color(red: 63 / 255, green: 255 / 255, blue: 154 / 255)
        }
    }
}
