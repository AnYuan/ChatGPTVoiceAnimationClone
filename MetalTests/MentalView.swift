import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        mtkView.framebufferOnly = true

        // Set up for animation
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false

        context.coordinator.setupMetal(mtkView)
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Updates happen through MTKViewDelegate
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice!
        var pipelineState: MTLRenderPipelineState!
        var commandQueue: MTLCommandQueue!
        var startTime: CFTimeInterval!

        func setupMetal(_ view: MTKView) {
            guard let device = view.device else { return }
            self.device = device
            self.startTime = CACurrentMediaTime()

            // Create the pipeline state
            let library = device.makeDefaultLibrary()
            let vertexFunction = library?.makeFunction(name: "vertex_main")
            let fragmentFunction = library?.makeFunction(name: "fragment_main")

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                commandQueue = device.makeCommandQueue()
                print("Metal pipeline set up successfully")
            } catch {
                print("Failed to create pipeline state: \(error)")
            }
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle resize if needed
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }

            // Calculate elapsed time
            var elapsed = Float(CACurrentMediaTime() - startTime)

            commandEncoder.setRenderPipelineState(pipelineState)
            commandEncoder.setFragmentBytes(&elapsed, length: MemoryLayout<Float>.size, index: 0)
            commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            commandEncoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
