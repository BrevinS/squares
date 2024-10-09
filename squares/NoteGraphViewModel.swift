import SwiftUI
import Combine

class NoteGraphViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var nodes: [NoteNode] = []
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    private var timer: AnyCancellable?
    let canvasSize = CGSize(width: 3000, height: 3000) // Larger canvas for scrolling
    let nodeRadius: CGFloat = 30
    let repulsionStrength: CGFloat = 5000 // Increased from 1000
    let springStrength: CGFloat = 0.03 // Decreased from 0.05
    let centerAttraction: CGFloat = 0.000001 // Decreased from 0.01
    let damping: CGFloat = 0.7 // Slightly decreased from 0.8
    let minDistance: CGFloat = 150 // Increased from 100

    init() {
        loadSampleData()
        initializeNodePositions()
        startSimulation()
    }
    
    private func loadSampleData() {
       notes = [
           Note(title: "SwiftUI", content: "A framework for building user interfaces"),
           Note(title: "AWS", content: "Cloud computing services"),
           Note(title: "Obsidian", content: "A powerful knowledge base"),
           Note(title: "GraphQL", content: "A query language for APIs"),
           Note(title: "React", content: "A JavaScript library for building user interfaces"),
           Note(title: "Node.js", content: "JavaScript runtime built on Chrome's V8 JavaScript engine")
       ]
           
       notes[0].connections.append(notes[1].id)
       notes[1].connections.append(notes[2].id)
       notes[2].connections.append(notes[3].id)
       notes[3].connections.append(notes[4].id)
       notes[4].connections.append(notes[5].id)
       notes[5].connections.append(notes[0].id)
       }
       
        
    private func initializeNodePositions() {
        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        let radius = min(centerX, centerY) * 0.6 // Adjusted radius
        
        nodes = notes.enumerated().map { index, note in
            let angle = 2 * CGFloat.pi * CGFloat(index) / CGFloat(notes.count)
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            return NoteNode(id: note.id, position: CGPoint(x: x, y: y))
        }
    }
        
    func startSimulation() {
        timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateNodes()
            }
    }
        
    func updateNodes() {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        var totalMovement: CGFloat = 0
        
        for i in 0..<nodes.count {
            var force = CGPoint.zero
            
            // Center gravity
            let directionToCenter = CGPoint(x: center.x - nodes[i].position.x, y: center.y - nodes[i].position.y)
            let distanceToCenter = sqrt(directionToCenter.x * directionToCenter.x + directionToCenter.y * directionToCenter.y)
            force.x += directionToCenter.x * centerAttraction * distanceToCenter
            force.y += directionToCenter.y * centerAttraction * distanceToCenter
            
            // Repulsion from other nodes
            for j in 0..<nodes.count where i != j {
                let dx = nodes[i].position.x - nodes[j].position.x
                let dy = nodes[i].position.y - nodes[j].position.y
                let distanceSquared = max(dx * dx + dy * dy, minDistance * minDistance)
                let distance = sqrt(distanceSquared)
                let repulsion = repulsionStrength / distanceSquared
                force.x += dx / distance * repulsion
                force.y += dy / distance * repulsion
            }
            
            // Spring force for connections
            if let note = notes.first(where: { $0.id == nodes[i].id }) {
                for connectedId in note.connections {
                    if let connectedIndex = nodes.firstIndex(where: { $0.id == connectedId }) {
                        let dx = nodes[connectedIndex].position.x - nodes[i].position.x
                        let dy = nodes[connectedIndex].position.y - nodes[i].position.y
                        let distance = sqrt(dx * dx + dy * dy)
                        force.x += dx * springStrength * (distance - minDistance) / distance
                        force.y += dy * springStrength * (distance - minDistance) / distance
                    }
                }
            }
            
            // Update velocity and position
            nodes[i].velocity.x = (nodes[i].velocity.x + force.x) * damping
            nodes[i].velocity.y = (nodes[i].velocity.y + force.y) * damping
            nodes[i].position.x += nodes[i].velocity.x
            nodes[i].position.y += nodes[i].velocity.y
            
            // Constrain to canvas
            nodes[i].position.x = max(nodeRadius, min(canvasSize.width - nodeRadius, nodes[i].position.x))
            nodes[i].position.y = max(nodeRadius, min(canvasSize.height - nodeRadius, nodes[i].position.y))
            
            // Calculate total movement
            totalMovement += abs(nodes[i].velocity.x) + abs(nodes[i].velocity.y)
        }
    }
        
    func getConnections() -> [(UUID, UUID)] {
        var connections: [(UUID, UUID)] = []
        for note in notes {
            for connection in note.connections {
                connections.append((note.id, connection))
            }
        }
        return connections
    }
    
    func addNote(title: String, content: String) {
        let newNote = Note(title: title, content: content)
        notes.append(newNote)
        let newNode = NoteNode(id: newNote.id, position: CGPoint(x: CGFloat.random(in: 100...(canvasSize.width - 100)),
                                                                 y: CGFloat.random(in: 100...(canvasSize.height - 100))))
        nodes.append(newNode)
        startSimulation() // Restart simulation to incorporate new node
    }
    }
