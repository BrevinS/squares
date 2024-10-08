import SwiftUI

struct NoteGraphView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Note Graph")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            // Placeholder for the graph or list of notes
            Text("Your notes will appear here")
                .foregroundColor(.gray)
            
            // Add more components here as needed
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
    }
}

struct NoteGraphView_Previews: PreviewProvider {
    static var previews: some View {
        NoteGraphView()
    }
}
