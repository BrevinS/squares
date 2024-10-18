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
    var color: Color = .gray  // Default color
    var tags: [String] = []   // Array to store tags
}

struct NoteNode: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGPoint = .zero
    var acceleration: CGPoint = .zero
    var color: Color  // Add color property
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
        .position(x: position.x, y: position.y)
    }
}

struct SliderView: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let label: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .foregroundColor(.white)
            HStack {
                Slider(value: $value, in: range)
                    .accentColor(.white)
                Text(String(format: "%.2f", value))
                    .foregroundColor(.white)
                    .frame(width: 40)
            }
        }
    }
}

struct GroupBox<Content: View>: View {
    let label: String
    let content: Content
    
    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.headline)
                .foregroundColor(.white)
            content
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SettingsView: View {
    @Binding var nodeSize: CGFloat
    @Binding var connectionThickness: CGFloat
    @Binding var centerForce: CGFloat
    @Binding var repelForce: CGFloat
    @Binding var linkForce: CGFloat
    @Binding var isShowingSettings: Bool

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.title)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    isShowingSettings = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding(.bottom)
            
            ScrollView {
                VStack(spacing: 20) {
                    SettingsGroup("Graph Appearance") {
                        SliderView(value: $nodeSize, range: 10...50, label: "Node Size")
                        SliderView(value: $connectionThickness, range: 0.5...5, label: "Connection Thickness")
                    }
                    
                    SettingsGroup("Physics Forces") {
                        SliderView(value: $centerForce, range: 0.025...0.1, label: "Center Force")
                        SliderView(value: $repelForce, range: 1000...100000, label: "Repel Force")
                        SliderView(value: $linkForce, range: 0...0.1, label: "Link Force")
                    }
                }
            }
        }
        .padding()
        .frame(width: 350, height: 500)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            content
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
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
    @State private var newNoteColor: Color = .gray
    @State private var newNoteTags: String = ""
    @State private var isShowingSettings: Bool = false
    
    // Gesture states
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    
    // Colors
    let backgroundColor = Color(red: 14/255, green: 17/255, blue: 22/255)
    let headerBackgroundColor = Color(red: 30/255, green: 30/255, blue: 30/255)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                headerBackgroundColor.edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Custom navigation bar
                    HStack {
                        settingsButton
                        Spacer()
                        Text("Note Graph")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Spacer()
                        addButton
                    }
                    .padding(.horizontal)
                    .padding(.top, 1)
                    .padding(.bottom, 10)
                    .background(backgroundColor)
                    
                    graphContent(in: geometry)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                if isShowingSettings {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            isShowingSettings = false
                        }
                    
                    SettingsView(
                        nodeSize: $viewModel.nodeSize,
                        connectionThickness: $viewModel.connectionThickness,
                        centerForce: $viewModel.centerForce,
                        repelForce: $viewModel.repelForce,
                        linkForce: $viewModel.linkForce,
                        isShowingSettings: $isShowingSettings
                    )
                    .transition(.move(edge: .top))
                    .animation(.easeInOut, value: isShowingSettings)
                }
            }
        }
        .gesture(graphGestures)
        .sheet(item: $selectedNote) { note in
            NoteView(note: note)
        }
        .sheet(isPresented: $isAddingNote) {
            addNoteView
        }
        .onAppear {
            resetView()
        }
    }
    
    private var graphGestures: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if !isShowingSettings {
                        state = value.translation
                    }
                }
                .onEnded { value in
                    if !isShowingSettings {
                        offset.width += value.translation.width
                        offset.height += value.translation.height
                    }
                },
            MagnificationGesture()
                .updating($magnifyBy) { value, state, _ in
                    if !isShowingSettings {
                        state = value
                    }
                }
                .onEnded { value in
                    if !isShowingSettings {
                        scale *= value
                        scale = min(max(scale, 0.5), 2.0)
                    }
                }
        )
    }
    
    private func graphContent(in geometry: GeometryProxy) -> some View {
        let centeringOffset = calculateCenteringOffset(for: geometry)
        return ZStack {
            // Draw connections
            Path { path in
                for connection in viewModel.getConnections() {
                    if let fromNode = viewModel.nodes.first(where: { $0.id == connection.from }),
                       let toNode = viewModel.nodes.first(where: { $0.id == connection.to }) {
                        path.move(to: nodePosition(fromNode, with: centeringOffset))
                        path.addLine(to: nodePosition(toNode, with: centeringOffset))
                    }
                }
            }
            .stroke(Color(red: 63/255, green: 63/255, blue: 63/255), lineWidth: viewModel.connectionThickness)
            
            ForEach(viewModel.nodes) { node in
                if let note = viewModel.notes.first(where: { $0.id == node.id }) {
                    NodeView(note: note, nodeSize: viewModel.nodeSize, position: nodePosition(node, with: centeringOffset), nodeColor: node.color)
                        .onTapGesture {
                            self.selectedNote = note
                        }
                }
            }
        }
        .scaleEffect(scale * magnifyBy)
        .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
    }
    
    private func calculateCenteringOffset(for geometry: GeometryProxy) -> CGSize {
        let nodes = viewModel.nodes
        guard !nodes.isEmpty else { return .zero }
        
        let avgX = nodes.map { $0.position.x }.reduce(0, +) / CGFloat(nodes.count)
        let avgY = nodes.map { $0.position.y }.reduce(0, +) / CGFloat(nodes.count)
        
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        return CGSize(width: centerX - avgX, height: centerY - avgY)
    }
    
    private func nodePosition(_ node: NoteNode, with centeringOffset: CGSize) -> CGPoint {
        return CGPoint(
            x: node.position.x + centeringOffset.width,
            y: node.position.y + centeringOffset.height
        )
    }
        
    private var settingsButton: some View {
        Button(action: {
            isShowingSettings.toggle()
        }) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 28))
                .foregroundColor(.orange)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            isAddingNote = true
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.orange)
        }
    }
    
    private func resetView() {
        let (_, newScale) = viewModel.centerView()
        scale = newScale
        offset = .zero
    }
    
    private var addNoteView: some View {
        NavigationView {
            Form {
                Section(header: Text("New Note")) {
                    TextField("Title", text: $newNoteTitle)
                    TextEditor(text: $newNoteContent)
                        .frame(height: 200)
                    ColorPicker("Node Color", selection: $newNoteColor)
                    TextField("Tags (comma-separated)", text: $newNoteTags)
                }
                
                Section {
                    Button("Add Note") {
                        let tags = newNoteTags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        viewModel.addNote(title: newNoteTitle, content: newNoteContent, color: newNoteColor, tags: tags)
                        newNoteTitle = ""
                        newNoteContent = ""
                        newNoteColor = .gray
                        newNoteTags = ""
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
