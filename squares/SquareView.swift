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
    
    @FetchRequest private var habitEntries: FetchedResults<HabitEntry>
    
    init(date: Date, isVisible: Bool, blocksDropped: Bool, index: Int, totalItems: Int,
         isExpanded: Bool, workout: LocalWorkout?, animationDelay: Double, onTap: @escaping () -> Void) {
        self.date = date
        self.isVisible = isVisible
        self.blocksDropped = blocksDropped
        self.index = index
        self.totalItems = totalItems
        self.isExpanded = isExpanded
        self.workout = workout
        self.animationDelay = animationDelay
        self.onTap = onTap
        
        // Create fetch request for habit entries on this date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        _habitEntries = FetchRequest(
            entity: HabitEntry.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \HabitEntry.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@ AND completed == YES",
                                 startOfDay as NSDate,
                                 endOfDay as NSDate)
        )
    }
    
    private var squareColor: Color {
        if let workout = workout, workout.type == "Run" {
            return getColorWithIntensity(distance: workout.distance)
        }
        return Color(red: 23/255, green: 27/255, blue: 33/255)
    }
    
    private func getColorWithIntensity(distance: Double?) -> Color {
        guard let distance = distance else { return .clear }
        
        if distance < 1000 {
            return Color.blue.opacity(0.3)
        } else if distance < 5000 {
            return Color.blue.opacity(0.5)
        } else if distance < 10000 {
            return Color.blue.opacity(0.7)
        } else {
            return Color.blue.opacity(0.9)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Base square with workout color
                RoundedRectangle(cornerRadius: isExpanded ? 0 : 8)
                    .fill(squareColor)
                
                // Habit entries (shown as small circles)
                if !habitEntries.isEmpty {
                    GeometryReader { geometry in
                        let size: CGFloat = 8
                        let padding: CGFloat = 4
                        let maxPerRow = 3
                        
                        ForEach(Array(habitEntries.prefix(6).enumerated()), id: \.element.id) { index, entry in
                            Circle()
                                .fill(Color(hex: entry.habit?.colorHex ?? "#808080") ?? .gray)
                                .frame(width: size, height: size)
                                .position(
                                    x: padding + CGFloat(index % maxPerRow) * (size + padding),
                                    y: padding + CGFloat(index / maxPerRow) * (size + padding)
                                )
                        }
                        
                        if habitEntries.count > 6 {
                            Text("+\(habitEntries.count - 6)")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                                .position(x: geometry.size.width - 12, y: geometry.size.height - 8)
                        }
                    }
                }
                
                // Border
                RoundedRectangle(cornerRadius: isExpanded ? 0 : 8)
                    .stroke(Color(red: 14/255, green: 17/255, blue: 22/255), lineWidth: isExpanded ? 0 : 5)
            }
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
