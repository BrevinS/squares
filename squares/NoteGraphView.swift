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
    var velocity: CGPoint = .zero
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

struct MetalView: UIViewRepresentable {
    @ObservedObject var viewModel: NoteGraphViewModel
    @Binding var offset: CGSize
    @Binding var scale: CGFloat
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.enableSetNeedsDisplay = true
        if let metalRenderer = MetalGraphRenderer(metalView: mtkView) {
            context.coordinator.renderer = metalRenderer
        } else {
            print("Failed to initialize Metal renderer")
        }
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.update(viewModel: viewModel, offset: offset, scale: scale)
        uiView.setNeedsDisplay()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: MetalView
        var renderer: MetalGraphRenderer?
        
        init(_ parent: MetalView) {
            self.parent = parent
        }
        
        func update(viewModel: NoteGraphViewModel, offset: CGSize, scale: CGFloat) {
            renderer?.updateNodes(viewModel.nodes, connections: viewModel.getConnections())
            renderer?.setOffset(CGPoint(x: offset.width, y: offset.height))
            renderer?.setScale(scale)
        }
    }
}

struct NoteGraphView: View {
    @StateObject private var viewModel = NoteGraphViewModel()
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 0.5
    @State private var selectedNote: Note? = nil
    @State private var isAddingNote: Bool = false
    @State private var newNoteTitle: String = ""
    @State private var newNoteContent: String = ""
    
    var body: some View {
        ZStack {
            if MTLCreateSystemDefaultDevice() != nil {
                MetalView(viewModel: viewModel, offset: $offset, scale: $scale)
                    .edgesIgnoringSafeArea(.all)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: offset.width + value.translation.width,
                                    height: offset.height + value.translation.height
                                )
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value.magnitude
                            }
                    )
            } else {
                Text("Metal is not supported on this device")
                    .foregroundColor(.red)
            }
            
            // Overlay for node selection
            ForEach(viewModel.nodes) { node in
                if let note = viewModel.notes.first(where: { $0.id == node.id }) {
                    Circle()
                        .fill(Color.blue.opacity(0.001)) // Nearly transparent for hit testing
                        .frame(width: viewModel.nodeRadius * 2, height: viewModel.nodeRadius * 2)
                        .position(node.position)
                        .onTapGesture {
                            selectedNote = note
                        }
                }
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isAddingNote = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedNote) { note in
            NoteView(note: note)
        }
        .sheet(isPresented: $isAddingNote) {
            VStack {
                Text("Add New Note")
                    .font(.largeTitle)
                    .padding()
                
                TextField("Title", text: $newNoteTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextEditor(text: $newNoteContent)
                    .frame(height: 200)
                    .border(Color.gray, width: 1)
                    .padding()
                
                Button("Add Note") {
                    addNewNote()
                }
                .disabled(newNoteTitle.isEmpty)
                .padding()
            }
            .padding()
        }
    }
    
    private func addNewNote() {
        viewModel.addNote(title: newNoteTitle, content: newNoteContent)
        newNoteTitle = ""
        newNoteContent = ""
        isAddingNote = false
    }
}

struct NoteGraphView_Previews: PreviewProvider {
    static var previews: some View {
        NoteGraphView()
    }
}
