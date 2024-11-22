import SwiftUI

struct SquareView: View {
    let date: Date
    let isVisible: Bool
    let blocksDropped: Bool
    let index: Int
    let totalItems: Int
    let isExpanded: Bool
    let workout: LocalWorkout?
    let animationDelay: Double
    let onTap: () -> Void
    
    private func getColorWithIntensity(baseColor: Color) -> Color {
        guard let distance = workout?.distance else {
            return Color(red: 23/255, green: 27/255, blue: 33/255)
        }
        
        if distance < 1000 {
            return baseColor.opacity(0.3)
        } else if distance < 5000 {
            return baseColor.opacity(0.5)
        } else if distance < 10000 {
            return baseColor.opacity(0.7)
        } else {
            return baseColor.opacity(0.9)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: isExpanded ? 0 : 8)
                .fill(getColorWithIntensity(baseColor: WorkoutColors.getColor(for: workout?.type)))
                .overlay(
                    RoundedRectangle(cornerRadius: isExpanded ? 0 : 8)
                        .stroke(Color(red: 14/255, green: 17/255, blue: 22/255), lineWidth: isExpanded ? 0 : 5)
                )
                .frame(width: isExpanded ? 41 : 40, height: isExpanded ? 41 : 40)
                .opacity(blocksDropped && isVisible ? 1 : 0)
                .animation(
                    isVisible ? Animation.easeIn(duration: 0.15).delay(animationDelay) : .none,
                    value: blocksDropped
                )
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .disabled(isExpanded)
    }
}
