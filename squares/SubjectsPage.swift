import SwiftUI

struct Subject: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    var isDefaultSelected: Bool
    
    static func defaultSubjects() -> [Subject] {
        [
            Subject(name: "Workouts", color: .orange, isDefaultSelected: true),
            Subject(name: "Running", color: .blue, isDefaultSelected: true),
            Subject(name: "Cycling", color: .green, isDefaultSelected: false)
        ]
    }
}

struct SubjectsPage: View {
    @State private var showAddSubject = false
    @State private var subjects: [Subject] = [
        Subject(name: "Running", color: .orange, isDefaultSelected: true),
        Subject(name: "Reading", color: .blue, isDefaultSelected: false),
        Subject(name: "Cycling", color: .green, isDefaultSelected: false)
    ]
    
    var body: some View {
        VStack {
            List(subjects) { subject in
                HStack {
                    Circle()
                        .fill(subject.color)
                        .frame(width: 12, height: 12)
                    Text(subject.name)
                        .foregroundColor(subject.color)
                }
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
