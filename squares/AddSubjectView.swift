import SwiftUI

struct AddSubjectView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var subjects: [String]
    @State private var newSubjectName: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter subject name", text: $newSubjectName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.top, 20) // Add top padding to move it down a bit
                
                    Spacer() // Push remaining content to the bottom
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add Subject")
                        .foregroundColor(.white) // Set the title color to white
                        .font(.headline) // Adjust font size as needed
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.orange), // Orange color for Cancel button
                trailing: Button(action: {
                    if !newSubjectName.isEmpty {
                        subjects.append(newSubjectName)
                        newSubjectName = ""
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Create")
                        .foregroundColor(.orange) // Orange color for Create button
                        .font(.headline) // Font size
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
