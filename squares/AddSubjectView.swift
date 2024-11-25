import SwiftUI

struct ColorCircle: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }
            }
        }
    }
}

struct AddSubjectView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: HabitsViewModel
    
    @State private var habitName = ""
    @State private var selectedColor: Color = .blue
    @State private var isBinary = false
    @State private var hasNotes = false
    @State private var isDefaultHabit = false
    
    let colors: [Color] = [
        .blue, .green, .orange, .red, .purple,
        .yellow, .pink, .indigo, .cyan, .mint
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Habit Details")) {
                    TextField("Habit Name", text: $habitName)
                    
                    Toggle("Binary Habit (Done/Not Done)", isOn: $isBinary)
                        .onChange(of: isBinary) { _, newValue in
                            if newValue {
                                hasNotes = false
                            }
                        }
                    
                    if !isBinary {
                        Toggle("Allow Notes", isOn: $hasNotes)
                    }
                    
                    Toggle("Set as Default", isOn: $isDefaultHabit)
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            ColorCircle(
                                color: color,
                                isSelected: selectedColor == color,
                                action: { selectedColor = color }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Habit")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { saveHabit() }
                    .disabled(habitName.isEmpty)
            )
        }
    }
    
    private func saveHabit() {
        print("💾 Saving new habit: \(habitName)")
        viewModel.addHabit(
            name: habitName,
            color: selectedColor,
            isBinary: isBinary,
            hasNotes: hasNotes,
            isDefault: isDefaultHabit
        )
        dismiss()
    }
}
