import MetalKit
import simd

class MetalGraphRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    var vertexBuffer: MTLBuffer?
    var nodes: [NoteNode] = []
    var connections: [(UUID, UUID)] = []
    var viewportSize: vector_uint2 = vector_uint2(1, 1)
    var offset: CGPoint = .zero
    var scale: CGFloat = 1.0

    init?(metalView: MTKView) {
        super.init()
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return nil
        }
        self.device = device
        metalView.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            print("Failed to create command queue")
            return nil
        }
        self.commandQueue = commandQueue
        
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create default library")
            return nil
        }
        
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        // Set up vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
            return nil
        }
        
        metalView.delegate = self
            metalView.clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0)
        }
        
        func updateNodes(_ newNodes: [NoteNode], connections: [(UUID, UUID)]) {
            self.nodes = newNodes
            self.connections = connections
            updateVertexBuffer()
        }
        
        func setViewport(size: CGSize) {
            viewportSize = vector_uint2(UInt32(size.width), UInt32(size.height))
        }
        
        func setOffset(_ newOffset: CGPoint) {
            offset = newOffset
        }
        
        func setScale(_ newScale: CGFloat) {
            scale = newScale
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            setViewport(size: size)
        }
        
        func updateVertexBuffer() {
            var vertices: [Vertex] = []
            
            // Add vertices for connections
            for connection in connections {
                if let fromNode = nodes.first(where: { $0.id == connection.0 }),
                   let toNode = nodes.first(where: { $0.id == connection.1 }) {
                    vertices.append(Vertex(position: SIMD2<Float>(Float(fromNode.position.x), Float(fromNode.position.y)),
                                           color: SIMD4<Float>(0.5, 0.5, 0.5, 0.5)))
                    vertices.append(Vertex(position: SIMD2<Float>(Float(toNode.position.x), Float(toNode.position.y)),
                                           color: SIMD4<Float>(0.5, 0.5, 0.5, 0.5)))
                }
            }
            
            // Add vertices for nodes
            for node in nodes {
                let x = Float(node.position.x)
                let y = Float(node.position.y)
                let radius: Float = 30.0
                let segments = 20
                
                let nodeColor = SIMD4<Float>(0.2, 0.2, 0.2, 1.0)
                
                for i in 0...segments {
                    let angle = Float(i) * (2.0 * .pi / Float(segments))
                    vertices.append(Vertex(position: SIMD2<Float>(x + cos(angle) * radius, y + sin(angle) * radius),
                                           color: nodeColor))
                    if i > 0 && i < segments {
                        vertices.append(Vertex(position: SIMD2<Float>(x, y),
                                               color: nodeColor))
                    }
                }
            }
            
            vertexBuffer = device?.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue?.makeCommandBuffer(),
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
                  let pipelineState = pipelineState,
                  let vertexBuffer = vertexBuffer else {
                return
            }
            
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            
            let scaledWidth = Double(viewportSize.x) / Double(scale)
            let scaledHeight = Double(viewportSize.y) / Double(scale)
            renderEncoder.setViewport(MTLViewport(originX: Double(-offset.x / scale),
                                                  originY: Double(-offset.y / scale),
                                                  width: scaledWidth,
                                                  height: scaledHeight,
                                                  znear: 0.0, zfar: 1.0))
            
            // Draw connections
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: connections.count * 2)
            
            // Draw nodes
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: connections.count * 2, vertexCount: nodes.count * 22)
            
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
