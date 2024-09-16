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
    @Environment(\.presentationMode) var presentationMode
    @Binding var subjects: [String]
    @State private var newSubjectName: String = ""
    @State private var selectedColor: Color = .blue
    
    let colors: [Color] = [.blue, .purple, .pink, .orange, .yellow, .green]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Subject Name")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.horizontal)
                
                TextField("Enter subject name", text: $newSubjectName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                
                Text("Subject Color")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.horizontal)
                
                HStack(spacing: 15) {
                    ForEach(colors, id: \.self) { color in
                        ColorCircle(color: color, isSelected: selectedColor == color) {
                            selectedColor = color
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add Subject")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.orange),
                trailing: Button(action: {
                    if !newSubjectName.isEmpty {
                        // Here you might want to save both the name and color
                        subjects.append(newSubjectName)
                        newSubjectName = ""
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Create")
                        .foregroundColor(.orange)
                        .font(.headline)
                }
            )
            .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
        }
    }
}

struct AddSubjectView_Previews: PreviewProvider {
    static var previews: some View {
        AddSubjectView(subjects: .constant([]))
    }
}
