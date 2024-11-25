import SwiftUI

struct ColorSliderView: View {
    @Binding var selectedColor: Color
    @State private var hue: Double = 0
    @State private var saturation: Double = 0.8
    @State private var brightness: Double = 0.8
    
    var body: some View {
        VStack(spacing: 12) {
            // Color preview
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedColor)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            // Hue slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Hue")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                GeometryReader { geometry in
                    LinearGradient(gradient: Gradient(colors: stride(from: 0, to: 1, by: 0.01).map {
                        Color(hue: $0, saturation: saturation, brightness: brightness)
                    }), startPoint: .leading, endPoint: .trailing)
                    .cornerRadius(6)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                hue = min(max(0, value.location.x / geometry.size.width), 1)
                                updateSelectedColor()
                            }
                    )
                }
                .frame(height: 20)
            }
            
            // Saturation slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Saturation")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                GeometryReader { geometry in
                    LinearGradient(gradient: Gradient(colors: [
                        Color(hue: hue, saturation: 0, brightness: brightness),
                        Color(hue: hue, saturation: 1, brightness: brightness)
                    ]), startPoint: .leading, endPoint: .trailing)
                    .cornerRadius(6)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                saturation = min(max(0, value.location.x / geometry.size.width), 1)
                                updateSelectedColor()
                            }
                    )
                }
                .frame(height: 20)
            }
            
            // Brightness slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Brightness")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                GeometryReader { geometry in
                    LinearGradient(gradient: Gradient(colors: [
                        Color(hue: hue, saturation: saturation, brightness: 0),
                        Color(hue: hue, saturation: saturation, brightness: 1)
                    ]), startPoint: .leading, endPoint: .trailing)
                    .cornerRadius(6)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                brightness = min(max(0, value.location.x / geometry.size.width), 1)
                                updateSelectedColor()
                            }
                    )
                }
                .frame(height: 20)
            }
        }
    }
    
    private func updateSelectedColor() {
        selectedColor = Color(hue: hue, saturation: saturation, brightness: brightness)
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
                    ColorSliderView(selectedColor: $selectedColor)
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
