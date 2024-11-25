import SwiftUI
import CoreData

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
    
    enum WorkoutColors {
        static let defaultColor = Color(red: 23/255, green: 27/255, blue: 33/255)
        static let runColor = Color.blue
        
        static func getColor(for workoutType: String?) -> Color {
            guard let type = workoutType,
                  type == "Run" else {
                return defaultColor
            }
            return runColor
        }
    }
    
    private func getColorWithIntensity(distance: Double?) -> Color {
        // Only process Run workouts
        guard let workout = workout,
              workout.type == "Run",
              let distance = distance else {
            return WorkoutColors.defaultColor
        }
        
        // Use the predefined run color with intensity
        if distance < 1000 {
            return WorkoutColors.runColor.opacity(0.3)
        } else if distance < 5000 {
            return WorkoutColors.runColor.opacity(0.5)
        } else if distance < 10000 {
            return WorkoutColors.runColor.opacity(0.7)
        } else {
            return WorkoutColors.runColor.opacity(0.9)
        }
    }
    
    private func getSquareColor() -> Color {
        if let workout = workout,
           workout.type == "Run" {
            return getColorWithIntensity(distance: workout.distance)
        }
        return WorkoutColors.defaultColor
    }
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: isExpanded ? 0 : 8)
                .fill(getSquareColor())
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
