import SwiftUI
import MetalKit

struct Vertex {
    var position: SIMD2<Float>
    var color: SIMD4<Float>
}

struct Note: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    var connections: [UUID] = []
}

struct NoteNode: Identifiable {
    let id: UUID
    var position: CGPoint
}

struct NoteView: View {
    let note: Note
    
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

struct NodeView: View {
    let note: Note
    let nodeSize: CGFloat
    let position: CGPoint
    let nodeColor: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Circle()
                .fill(nodeColor)
                .frame(width: nodeSize, height: nodeSize)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            Text(note.title)
                .font(.system(size: 10))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: nodeSize * 1.2)
        }
        .position(x: position.x, y: position.y + nodeSize / 2 + 10) // Adjust position to account for title below
    }
}

struct NoteGraphView: View {
    @StateObject private var viewModel = NoteGraphViewModel()
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var selectedNote: Note? = nil
    @State private var isAddingNote: Bool = false
    @State private var newNoteTitle: String = ""
    @State private var newNoteContent: String = ""
    
    // Gesture and momentum states
    @GestureState private var fingerLocation: CGPoint? = nil
    @State private var lastFingerLocation: CGPoint? = nil
    @State private var velocity: CGSize = .zero
    @State private var isScrolling = false
    
    // Momentum constants
    let decelerationRate: CGFloat = 0.85
    let minimumVelocity: CGFloat = 0.1

    // Node appearance
    let baseNodeRadius: CGFloat = 20
    let maxNodeRadius: CGFloat = 40
    let connectionScaleFactor: CGFloat = 2

    // Colors
    let backgroundColor = Color(red: 30/255, green: 30/255, blue: 30/255)
    let lineColor = Color(red: 63/255, green: 63/255, blue: 63/255)
    let nodeColor = Color(red: 179/255, green: 179/255, blue: 179/255)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                // Draw connections
                Path { path in
                    for connection in viewModel.getConnections() {
                        if let fromNode = viewModel.nodes.first(where: { $0.id == connection.from }),
                           let toNode = viewModel.nodes.first(where: { $0.id == connection.to }) {
                            path.move(to: nodePosition(fromNode))
                            path.addLine(to: nodePosition(toNode))
                        }
                    }
                }
                .stroke(lineColor, lineWidth: 1)
                
                ForEach(viewModel.nodes) { node in
                    if let note = viewModel.notes.first(where: { $0.id == node.id }) {
                        NodeView(note: note, nodeSize: nodeSize(for: note), position: nodePosition(node), nodeColor: nodeColor)
                            .onTapGesture {
                                self.selectedNote = note
                            }
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($fingerLocation) { value, fingerLocation, _ in
                        fingerLocation = value.location
                        isScrolling = true
                    }
                    .onEnded { value in
                        isScrolling = false
                        let endVelocity = CGSize(
                            width: value.predictedEndLocation.x - value.location.x,
                            height: value.predictedEndLocation.y - value.location.y
                        )
                        velocity = CGSize(
                            width: endVelocity.width * 0.1,
                            height: endVelocity.height * 0.1
                        )
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / scale
                        scale *= delta
                        scale = min(max(scale, 0.5), 2.0)
                        
                        let zoomPoint = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        offset = CGSize(
                            width: (offset.width - zoomPoint.x) * delta + zoomPoint.x,
                            height: (offset.height - zoomPoint.y) * delta + zoomPoint.y
                        )
                    }
            )
        }
        .navigationBarTitle("Note Graph", displayMode: .inline)
        .navigationBarItems(trailing: addButton)
        .sheet(item: $selectedNote) { note in
            NoteView(note: note)
        }
        .sheet(isPresented: $isAddingNote) {
            addNoteView
        }
        .onAppear(perform: centerView)
        .onChange(of: fingerLocation) { newValue in
            updateOffset(newFingerLocation: newValue)
        }
        .onReceive(Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()) { _ in
            applyMomentum()
        }
    }
    
    private func nodeSize(for note: Note) -> CGFloat {
        let connectionCount = CGFloat(note.connections.count)
        let size = baseNodeRadius + min(connectionCount * connectionScaleFactor, maxNodeRadius - baseNodeRadius)
        return size * 2 // Diameter
    }
    
    private func nodePosition(_ node: NoteNode) -> CGPoint {
        return CGPoint(
            x: node.position.x * scale + offset.width,
            y: node.position.y * scale + offset.height
        )
    }
    
    private func nodeTitlePosition(_ node: NoteNode) -> CGPoint {
        let nodePos = nodePosition(node)
        return CGPoint(x: nodePos.x, y: nodePos.y + viewModel.nodeRadius + 10)
    }
    
    private func updateOffset(newFingerLocation: CGPoint?) {
        guard let newFingerLocation = newFingerLocation else {
            lastFingerLocation = nil
            return
        }
        
        if let lastFingerLocation = lastFingerLocation {
            let dx = newFingerLocation.x - lastFingerLocation.x
            let dy = newFingerLocation.y - lastFingerLocation.y
            
            offset = CGSize(
                width: offset.width + dx,
                height: offset.height + dy
            )
        }
        
        lastFingerLocation = newFingerLocation
    }
    
    private func applyMomentum() {
        guard !isScrolling else { return }
        
        if abs(velocity.width) > minimumVelocity || abs(velocity.height) > minimumVelocity {
            offset = CGSize(
                width: offset.width + velocity.width,
                height: offset.height + velocity.height
            )
            
            velocity = CGSize(
                width: velocity.width * decelerationRate,
                height: velocity.height * decelerationRate
            )
        } else {
            velocity = .zero
        }
    }
    
    private func centerView() {
        let avgX = viewModel.nodes.map { $0.position.x }.reduce(0, +) / CGFloat(viewModel.nodes.count)
        let avgY = viewModel.nodes.map { $0.position.y }.reduce(0, +) / CGFloat(viewModel.nodes.count)
        let screenCenter = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        offset = CGSize(width: screenCenter.x - avgX * scale, height: screenCenter.y - avgY * scale)
    }
    
    private var addButton: some View {
        Button(action: {
            isAddingNote = true
        }) {
            Image(systemName: "plus")
        }
    }
    
    private var addNoteView: some View {
        NavigationView {
            Form {
                Section(header: Text("New Note")) {
                    TextField("Title", text: $newNoteTitle)
                    TextEditor(text: $newNoteContent)
                        .frame(height: 200)
                }
                
                Section {
                    Button("Add Note") {
                        viewModel.addNote(title: newNoteTitle, content: newNoteContent)
                        newNoteTitle = ""
                        newNoteContent = ""
                        isAddingNote = false
                    }
                    .disabled(newNoteTitle.isEmpty)
                }
            }
            .navigationBarTitle("Add New Note", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                isAddingNote = false
            })
        }
    }
}

struct NoteGraphView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NoteGraphView()
        }
    }
}
