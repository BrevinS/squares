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

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddEntry = false
    @State private var noteText = ""
    @State private var selectedDate = Date()
    @State private var isCompleted = false
    
    // Fetch entries for this habit
    @FetchRequest private var entries: FetchedResults<HabitEntry>
    
    init(habit: Habit) {
        self.habit = habit
        // Initialize the fetch request with a predicate for this habit
        _entries = FetchRequest(
            entity: HabitEntry.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \HabitEntry.date, ascending: false)],
            predicate: NSPredicate(format: "habit == %@", habit)
        )
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Circle()
                        .fill(Color(hex: habit.colorHex ?? "#808080") ?? .gray)
                        .frame(width: 20, height: 20)
                    
                    VStack(alignment: .leading) {
                        Text(habit.name ?? "Unnamed Habit")
                            .font(.title2)
                            .foregroundColor(Color(hex: habit.colorHex ?? "#808080") ?? .gray)
                        Text(habit.isBinary ? "Done/Not Done" : "With Notes")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section("Add New Entry") {
                DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                
                if habit.isBinary {
                    Toggle("Completed", isOn: $isCompleted)
                } else if habit.hasNotes {
                    TextEditor(text: $noteText)
                        .frame(height: 100)
                }
                
                Button(action: addEntry) {
                    Text("Add Entry")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: habit.colorHex ?? "#808080") ?? .gray)
            }
            
            Section("History") {
                if entries.isEmpty {
                    Text("No entries yet")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(entries) { entry in
                        EntryRowView(entry: entry)
                    }
                    .onDelete(perform: deleteEntries)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addEntry() {
        let newEntry = HabitEntry(context: viewContext)
        newEntry.id = UUID()
        newEntry.date = selectedDate
        newEntry.habit = habit
        
        if habit.isBinary {
            newEntry.completed = isCompleted
        } else if habit.hasNotes {
            newEntry.notes = noteText
            newEntry.completed = !noteText.isEmpty
        }
        
        do {
            try viewContext.save()
            // Reset input fields
            noteText = ""
            isCompleted = false
            selectedDate = Date()
        } catch {
            print("Error saving entry: \(error)")
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        offsets.forEach { index in
            viewContext.delete(entries[index])
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error deleting entries: \(error)")
        }
    }
}

struct EntryRowView: View {
    let entry: HabitEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(formatDate(entry.date ?? Date()))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if entry.habit?.isBinary ?? false {
                    Image(systemName: entry.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(entry.completed ? .green : .gray)
                }
            }
            
            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .padding(.top, 2)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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

struct HabitRowView: View {
    let habit: Habit
    
    var body: some View {
        NavigationLink(destination: HabitDetailView(habit: habit)) {
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
        }
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

struct SubjectsPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SubjectsPage(context: PersistenceController.preview.container.viewContext)
        }
    }
}
