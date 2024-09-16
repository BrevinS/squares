import SwiftUI

struct SubjectsPage: View {
    @State private var showAddSubject = false
    @State private var subjects: [String] = ["Subject 1", "Subject 2"]
    
    var body: some View {
        VStack {
            List(subjects, id: \.self) { subject in
                Text(subject)
                    .foregroundColor(.orange)
            }
            .navigationBarItems(trailing: Button(action: {
                showAddSubject.toggle()
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.orange)
            })
        }
        .sheet(isPresented: $showAddSubject) {
            AddSubjectView(subjects: $subjects)
        }
    }
        
}

struct SubjectsPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SubjectsPage()
        }
    }
}
