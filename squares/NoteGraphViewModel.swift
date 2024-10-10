import SwiftUI
import Combine

struct Connection: Hashable {
    let id = UUID()
    let from: UUID
    let to: UUID
}

class NoteGraphViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var nodes: [NoteNode] = []
    let canvasSize = CGSize(width: 1000, height: 1000) // Reduced canvas size
    let nodeRadius: CGFloat = 13 // Increased node size for visibility

    init() {
        loadSampleData()
        initializeNodePositions()
        updateConnections()
    }
    
    private func loadSampleData() {
        notes = [
            Note(title: "SwiftUI", content: "A framework for building user interfaces. Related to [[React]]"),
            Note(title: "AWS", content: "Cloud computing services. Often used with [[Node.js]]"),
            Note(title: "Obsidian", content: "A powerful knowledge base that inspired this project"),
            Note(title: "GraphQL", content: "A query language for APIs, often used with [[Node.js]] and [[React]]"),
            Note(title: "React", content: "A JavaScript library for building user interfaces. Can be used with [[GraphQL]]"),
            Note(title: "Node.js", content: "JavaScript runtime built on Chrome's V8 JavaScript engine. Works well with [[GraphQL]]")
        ]
    }
    
    private func initializeNodePositions() {
        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        let radius = min(centerX, centerY) * 0.5 // Smaller radius to keep nodes more centered
        
        nodes = notes.enumerated().map { index, note in
            let angle = 2 * CGFloat.pi * CGFloat(index) / CGFloat(notes.count)
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            return NoteNode(id: note.id, position: CGPoint(x: x, y: y))
        }
    }
    
    func updateConnections() {
        let pattern = "\\[\\[(.*?)\\]\\]"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        notes = notes.map { note in
            var updatedNote = note
            updatedNote.connections.removeAll()
            
            let range = NSRange(note.content.startIndex..., in: note.content)
            let matches = regex.matches(in: note.content, options: [], range: range)
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: note.content) {
                    let linkedTitle = String(note.content[range])
                    if let linkedNote = notes.first(where: { $0.title == linkedTitle }) {
                        updatedNote.connections.append(linkedNote.id)
                    }
                }
            }
            
            return updatedNote
        }
        
        print("Updated connections:")
        for note in notes {
            print("\(note.title): \(note.connections.count) connections")
        }
    }
    
    func getConnections() -> [Connection] {
        var connections: [Connection] = []
        for note in notes {
            for connection in note.connections {
                connections.append(Connection(from: note.id, to: connection))
            }
        }
        print("Total connections: \(connections.count)")
        return connections
    }
    
    func addNote(title: String, content: String) {
        let newNote = Note(title: title, content: content)
        notes.append(newNote)
        let newNode = NoteNode(id: newNote.id, position: CGPoint(x: CGFloat.random(in: nodeRadius...(canvasSize.width - nodeRadius)),
                                                                 y: CGFloat.random(in: nodeRadius...(canvasSize.height - nodeRadius))))
        nodes.append(newNode)
        updateConnections()
    }
}
