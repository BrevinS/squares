import SwiftUI
import Combine

struct Note: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    var connections: [UUID] = []
}

struct NoteNode: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGPoint = .zero
}

struct NoteView: View {
    var note: Note
    
    var body: some View {
        VStack {
            Text(note.title)
                .font(.largeTitle)
                .padding()
            Text(note.content)
                .padding()
            Spacer()
        }
        .navigationBarTitle("Note", displayMode: .inline)
    }
}

struct ConnectionLine: Shape {
    var from: CGPoint
    var to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

struct NoteGraphView: View {
    @StateObject private var viewModel = NoteGraphViewModel()
    @State private var selectedNote: Note? = nil
    @State private var zoomScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255).edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Note Graph")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .padding()
                
                ZStack {
                    // Draw connections between nodes
                    ForEach(viewModel.notes) { note in
                        ForEach(note.connections, id: \.self) { connectionId in
                            if let fromNode = viewModel.nodes.first(where: { $0.id == note.id }),
                               let toNode = viewModel.nodes.first(where: { $0.id == connectionId }) {
                                ConnectionLine(from: fromNode.position, to: toNode.position)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            }
                        }
                    }
                    
                    // Draw the nodes
                    ForEach(viewModel.nodes) { node in
                        if let note = viewModel.notes.first(where: { $0.id == node.id }) {
                            Circle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: viewModel.nodeRadius * 2, height: viewModel.nodeRadius * 2)
                                .position(node.position)
                                .overlay(
                                    Text(note.title.prefix(2))
                                        .foregroundColor(.white)
                                        .font(.system(size: 10))
                                )
                                .onTapGesture {
                                    selectedNote = note
                                }
                        }
                    }
                }
                .frame(width: viewModel.canvasSize.width, height: viewModel.canvasSize.height)
                .scaleEffect(zoomScale)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoomScale = value.magnitude
                        }
                )
            }
        }
        .sheet(item: $selectedNote) { note in
            NoteView(note: note)
        }
    }
}

// Keep the NoteView and NoteGraphView_Previews as they were
// Preview Provider
struct NoteGraphView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NoteGraphViewModel()
        
        // Add more sample notes
        viewModel.notes.append(contentsOf: [
            Note(title: "GraphQL", content: "A query language for APIs"),
            Note(title: "React", content: "A JavaScript library for building user interfaces"),
            Note(title: "Node.js", content: "JavaScript runtime built on Chrome's V8 JavaScript engine")
        ])
        
        // Add more sample nodes
        for note in viewModel.notes.suffix(3) {
            viewModel.nodes.append(NoteNode(id: note.id, position: CGPoint(x: CGFloat.random(in: 100...900), y: CGFloat.random(in: 100...900))))
        }
        
        // Add more connections
        viewModel.notes[2].connections.append(viewModel.notes[3].id)
        viewModel.notes[3].connections.append(viewModel.notes[4].id)
        viewModel.notes[4].connections.append(viewModel.notes[5].id)
        viewModel.notes[5].connections.append(viewModel.notes[0].id)
        
        return NoteGraphView()
            .environmentObject(viewModel)
            .previewLayout(.fixed(width: 1200, height: 1200))
    }
}
