import SwiftUI
import CoreData

class HabitsViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    @Published var habits: [Habit] = []
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchHabits()
    }
    
    func fetchHabits() {
        let request = NSFetchRequest<Habit>(entityName: "Habit")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.createdAt, ascending: true)]
        
        do {
            habits = try viewContext.fetch(request)
            print("📱 Fetched \(habits.count) habits from device")
            for habit in habits {
                print("   📍 Habit: \(habit.name), Binary: \(habit.isBinary), Notes: \(habit.hasNotes)")
            }
        } catch {
            print("❌ Error fetching habits: \(error)")
            habits = []
        }
    }
    
    func addHabit(name: String, color: Color, isBinary: Bool, hasNotes: Bool, isDefault: Bool) {
        let newHabit = Habit(context: viewContext)
        newHabit.id = UUID()
        newHabit.name = name
        newHabit.colorHex = color.toHex() ?? "#0000FF"
        newHabit.isBinary = isBinary
        newHabit.hasNotes = hasNotes
        newHabit.isDefaultHabit = isDefault
        newHabit.createdAt = Date()
        
        print("💾 Adding new habit: \(name)")
        
        do {
            try viewContext.save()
            print("✅ Successfully saved new habit")
            fetchHabits()
        } catch {
            print("❌ Error saving habit: \(error)")
        }
    }
}

struct SubjectsPage: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: HabitsViewModel
    @State private var showAddSubject = false
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: HabitsViewModel(context: context))
    }
    
    var body: some View {
        VStack {
            if viewModel.habits.isEmpty {
                emptyStateView
            } else {
                habitList
            }
        }
        .navigationBarItems(trailing: addButton)
        .sheet(isPresented: $showAddSubject) {
            AddSubjectView(viewModel: viewModel)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            print("🔄 SubjectsPage appeared - Refreshing habits")
            viewModel.fetchHabits()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Habits Yet")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Add your first habit to start tracking")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var habitList: some View {
        List {
            ForEach(viewModel.habits, id: \.id) { habit in
                HabitRowView(habit: habit)
            }
            .onDelete(perform: deleteHabits)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            print("➕ Add habit button tapped")
            showAddSubject = true
        }) {
            Image(systemName: "plus")
                .foregroundColor(.orange)
        }
    }
    
    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            let habit = viewModel.habits[index]
            print("🗑️ Deleting habit: \(habit.name)")
            viewContext.delete(habit)
        }
        
        do {
            try viewContext.save()
            print("✅ Successfully deleted habit(s)")
            viewModel.fetchHabits()
        } catch {
            print("❌ Error deleting habit(s): \(error)")
        }
    }
}

// MARK: - HabitRowView
struct HabitRowView: View {
    let habit: Habit
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: habit.colorHex ?? "#808080") ?? .gray)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                Text(habit.name ?? "Unnamed Habit")
                    .foregroundColor(Color(hex: habit.colorHex ?? "#808080") ?? .gray)
                
                Text(getHabitTypeDescription())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if habit.isDefaultHabit {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 12))
            }
        }
        .contentShape(Rectangle())
    }
    
    private func getHabitTypeDescription() -> String {
        if habit.isBinary {
            return "Done/Not Done"
        } else if habit.hasNotes {
            return "With Notes"
        } else {
            return "Basic Tracking"
        }
    }
}

extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
    
    init?(hex: String?) {
        guard let hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        
        var hexSanitized = hex.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            print("❌ Failed to parse hex color: \(hex)")
            return nil
        }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

struct SubjectsPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SubjectsPage(context: PersistenceController.preview.container.viewContext)
        }
    }
}
