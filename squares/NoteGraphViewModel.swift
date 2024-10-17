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
    @Published var nodeSize: CGFloat = 26
    @Published var connectionThickness: CGFloat = 1
    @Published var centerForce: CGFloat = 0.05
    @Published var repelForce: CGFloat = 8000
    @Published var linkForce: CGFloat = 0.05
    
    let canvasSize = CGSize(width: 1000, height: 1000)

    init() {
        loadSampleData()
        initializeNodePositions()
        updateConnections()
        startPhysicsSimulation()
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
            return NoteNode(id: note.id, position: CGPoint(x: x, y: y), color: note.color)
        }
    }
    
    func updateConnections() {
        let pattern = "\\[\\[(.*?)\\]\\]"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        notes = notes.map { note in
            var updatedNote = note
            updatedNote.connections.removeAll()
            
            // Handle wiki-style links
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
            
            // Handle tag-based connections
            for otherNote in notes where otherNote.id != note.id {
                if !Set(note.tags).isDisjoint(with: Set(otherNote.tags)) {
                    updatedNote.connections.append(otherNote.id)
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
    
    func addNote(title: String, content: String, color: Color, tags: [String]) {
        let newNote = Note(title: title, content: content, color: color, tags: tags)
        notes.append(newNote)
        let newNode = NoteNode(id: newNote.id,
                               position: CGPoint(x: CGFloat.random(in: nodeSize...(canvasSize.width - nodeSize)),
                                                 y: CGFloat.random(in: nodeSize...(canvasSize.height - nodeSize))),
                               color: color)
        nodes.append(newNode)
        updateConnections()
    }
    
    // Physics parameters
    let gravitationalConstant: CGFloat = 0.05
    let repulsionConstant: CGFloat = 8000
    let dampingFactor: CGFloat = 0.8 // Increased damping to slow down nodes more quickly
    let maxVelocity: CGFloat = 5 // Maximum velocity to prevent nodes from moving too fast

    private func applyForces() {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let connections = getConnections()

        for i in 0..<nodes.count {
            var node = nodes[i]
            
            // Center force
            let centerForceVector = CGPoint(
                x: (center.x - node.position.x) * centerForce,
                y: (center.y - node.position.y) * centerForce
            )
            node.acceleration = centerForceVector
            
            // Repel force
            for j in 0..<nodes.count where i != j {
                let otherNode = nodes[j]
                let distance = max(hypot(node.position.x - otherNode.position.x, node.position.y - otherNode.position.y), 1)
                let direction = CGPoint(x: node.position.x - otherNode.position.x, y: node.position.y - otherNode.position.y)
                
                let repulsionForce = CGPoint(
                    x: direction.x / distance * repelForce / (distance * distance),
                    y: direction.y / distance * repelForce / (distance * distance)
                )
                node.acceleration.x += repulsionForce.x
                node.acceleration.y += repulsionForce.y
            }
            
            // Link force
            for connection in connections {
                if connection.from == node.id,
                   let toNode = nodes.first(where: { $0.id == connection.to }) {
                    let distance = max(hypot(node.position.x - toNode.position.x, node.position.y - toNode.position.y), 1)
                    let direction = CGPoint(x: toNode.position.x - node.position.x, y: toNode.position.y - node.position.y)
                    
                    let linkForceVector = CGPoint(
                        x: direction.x * linkForce,
                        y: direction.y * linkForce
                    )
                    node.acceleration.x += linkForceVector.x
                    node.acceleration.y += linkForceVector.y
                }
            }
            
            nodes[i] = node
        }
    }

    func updateNodePositions() {
        applyForces()
        
        for i in 0..<nodes.count {
            var node = nodes[i]
            
            // Update velocity and position
            node.velocity.x = (node.velocity.x + node.acceleration.x) * dampingFactor
            node.velocity.y = (node.velocity.y + node.acceleration.y) * dampingFactor
            
            // Limit velocity
            let speed = hypot(node.velocity.x, node.velocity.y)
            if speed > maxVelocity {
                node.velocity.x *= maxVelocity / speed
                node.velocity.y *= maxVelocity / speed
            }
            
            node.position.x += node.velocity.x
            node.position.y += node.velocity.y
            
            // Keep nodes within canvas bounds
            node.position.x = max(nodeSize / 2, min(canvasSize.width - nodeSize / 2, node.position.x))
            node.position.y = max(nodeSize / 2, min(canvasSize.height - nodeSize / 2, node.position.y))
            
            // Reset acceleration
            node.acceleration = .zero
            
            nodes[i] = node
        }
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func centerView() -> (CGPoint, CGFloat) {
        let avgX = nodes.map { $0.position.x }.reduce(0, +) / CGFloat(nodes.count)
        let avgY = nodes.map { $0.position.y }.reduce(0, +) / CGFloat(nodes.count)
        let center = CGPoint(x: avgX, y: avgY)
        
        let maxDistance = nodes.map { node in
            hypot(node.position.x - center.x, node.position.y - center.y)
        }.max() ?? 0
        
        let scale = min(canvasSize.width, canvasSize.height) / (maxDistance * 2.5)
        
        return (center, scale)
    }

    // Start a physics simulation loop
    func startPhysicsSimulation() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            self.updateNodePositions()
        }
    }
}
