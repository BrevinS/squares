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
    @Binding var subjects: [Subject]
    @Environment(\.dismiss) var dismiss
    @State private var subjectName = ""
    @State private var selectedColor: Color = .orange
    @State private var isDefaultSelected = false
    
    // Expanded color options
    let colors: [Color] = [
        .orange, .blue, .green, .red, .purple,
        .yellow, .pink, .indigo, .cyan, .mint
    ]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Subject Name", text: $subjectName)
                
                Toggle("Set as Default", isOn: $isDefaultSelected)
                
                Section(header: Text("Color")) {
                    VStack(spacing: 12) {
                        // Color preview
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedColor)
                            .frame(height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Color grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                ColorCircle(
                                    color: color,
                                    isSelected: selectedColor == color,
                                    action: { selectedColor = color }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if isDefaultSelected {
                    Section(footer: Text("Default subjects are automatically selected in filters")) {
                        Text("This subject will be selected by default")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Add Subject")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Add") {
                    if !subjectName.isEmpty {
                        if isDefaultSelected {
                            subjects = subjects.map { subject in
                                Subject(name: subject.name, color: subject.color, isDefaultSelected: false)
                            }
                        }
                        
                        subjects.append(Subject(
                            name: subjectName,
                            color: selectedColor,
                            isDefaultSelected: isDefaultSelected
                        ))
                        dismiss()
                    }
                }
            )
        }
    }
}

struct AddSubjectView_Previews: PreviewProvider {
    static var previews: some View {
        AddSubjectView(subjects: .constant([]))
    }
}
