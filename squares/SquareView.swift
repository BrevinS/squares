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
    let selectedHabitName: String?
    
    @FetchRequest private var habitEntries: FetchedResults<HabitEntry>
    @FetchRequest private var runningHabit: FetchedResults<Habit>
    @State private var showAlert = false
    
    init(date: Date, isVisible: Bool, blocksDropped: Bool, index: Int, totalItems: Int,
         isExpanded: Bool, workout: LocalWorkout?, animationDelay: Double,
         selectedHabitName: String?, onTap: @escaping () -> Void) {
        self.date = date
        self.isVisible = isVisible
        self.blocksDropped = blocksDropped
        self.index = index
        self.totalItems = totalItems
        self.isExpanded = isExpanded
        self.workout = workout
        self.animationDelay = animationDelay
        self.selectedHabitName = selectedHabitName
        self.onTap = onTap
        
        // Fetch for habit entries - Fixed predicate
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "date >= %@ AND date < %@",
                       startOfDay as NSDate,
                       endOfDay as NSDate)
        ]
        
        if let habitName = selectedHabitName {
            predicates.append(NSPredicate(format: "habit.name == %@ AND completed == YES", habitName))
        }
        
        _habitEntries = FetchRequest(
            entity: HabitEntry.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \HabitEntry.date, ascending: true)],
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        )
        
        // Fetch for running habit color remains the same
        _runningHabit = FetchRequest(
            entity: Habit.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", "Running (Strava)")
        )
    }
    
    private var squareColor: Color {
        if selectedHabitName == "Running (Strava)", let workout = workout {
            if let runningHabitColor = runningHabit.first?.colorHex {
                let baseColor = Color(hex: runningHabitColor) ?? .blue
                return getColorWithIntensity(baseColor: baseColor, distance: workout.distance)
            }
        }
        
        if let firstEntry = habitEntries.first,
           let habit = firstEntry.habit,
           let colorHex = habit.colorHex {
            return Color(hex: colorHex) ?? Color(red: 23/255, green: 27/255, blue: 33/255)
        }
        
        return Color(red: 23/255, green: 27/255, blue: 33/255)
    }
    
    private func getColorWithIntensity(baseColor: Color, distance: Double?) -> Color {
        guard let distance = distance else { return baseColor.opacity(0.3) }
        
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
    
    private var habitEntry: HabitEntry? {
        habitEntries.first
    }
    
    private var isClickable: Bool {
        if selectedHabitName == "Running (Strava)" {
            return workout != nil
        }
        
        if let entry = habitEntry, let habit = entry.habit {
            return habit.hasNotes
        }
        
        return false
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: {
            print("Button tapped for date: \(formatDate(date))")
            
            // Only show alert if it's not a Running (Strava) day with workout
            if !(selectedHabitName == "Running (Strava)" && workout != nil) {
                showAlert = true
            }
            
            // Handle detailed view navigation
            if selectedHabitName == "Running (Strava)" && workout != nil {
                onTap()
            } else if let entry = habitEntry, let habit = entry.habit {
                if habit.hasNotes {
                    onTap()
                }
            }
        }) {
            ZStack {
                // Base square (always visible)
                RoundedRectangle(cornerRadius: isExpanded ? 0 : 8)
                    .fill(Color(red: 23/255, green: 27/255, blue: 33/255))
                    .frame(width: isExpanded ? 41 : 40, height: isExpanded ? 41 : 40)
                
                // Activity overlay
                if shouldShowActivity() {
                    RoundedRectangle(cornerRadius: isExpanded ? 0 : 8)
                        .fill(squareColor)
                        .frame(width: isExpanded ? 41 : 40, height: isExpanded ? 41 : 40)
                }
                
                // Border overlay
                RoundedRectangle(cornerRadius: isExpanded ? 0 : 8)
                    .stroke(Color(red: 14/255, green: 17/255, blue: 22/255), lineWidth: isExpanded ? 0 : 5)
            }
            .opacity(blocksDropped && isVisible ? 1 : 0)
            .animation(
                isVisible ? Animation.easeIn(duration: 0.15).delay(animationDelay) : .none,
                value: blocksDropped
            )
            .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .disabled(isExpanded)
        .alert(isPresented: $showAlert) {
            if let entry = habitEntry, let habit = entry.habit {
                // Show completion time for habits with entries
                return Alert(
                    title: Text(habit.name ?? "Habit"),
                    message: Text("Completed on \(formatDateTime(entry.date ?? date))"),
                    dismissButton: .default(Text("OK"))
                )
            } else if selectedHabitName != nil {
                // Show date for selected habit with no entry
                return Alert(
                    title: Text(selectedHabitName!),
                    message: Text("No activity on \(formatDate(date))"),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                // Show just the date for unselected squares
                return Alert(
                    title: Text("Date"),
                    message: Text(formatDate(date)),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
 
    private func shouldShowActivity() -> Bool {
        if selectedHabitName == "Running (Strava)" {
            return workout != nil
        } else {
            return !habitEntries.isEmpty
        }
    }
}
