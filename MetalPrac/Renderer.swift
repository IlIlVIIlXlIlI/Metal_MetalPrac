import Foundation
import MetalKit

let vertexData: [Float] = [-1, -1, 0, 1,
                            1, -1, 0, 1,
                           -1,  1, 0, 1,
                            1,  1, 0, 1]

let textureCoordinateData: [Float] = [0, 1,
                                      1, 1,
                                      0, 0,
                                      1, 0]


class Renderer: NSObject, MTKViewDelegate {
    let parent: MetalView
    var commandQueue: MTLCommandQueue?
    var vertexBuffer: MTLBuffer!
    var texCoordBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState?
    let renderPassDescriptor = MTLRenderPassDescriptor()
    var texture: MTLTexture!
   
        
    init(_ parent: MetalView) {
        self.parent = parent
    }
    
    func setup(device: MTLDevice, view: MTKView) {
        self.commandQueue = device.makeCommandQueue()
        
        // MTKTextureLoaderを初期化
        let textureLoader = MTKTextureLoader(device: device)
        // テクスチャをロード
        texture = try! textureLoader.newTexture(
            name: "highsierra",
            scaleFactor: view.contentScaleFactor,
            bundle: nil)
        
        makeBuffers(device: device)
        setupPipelineState(device: device, view: view)
    
    }

    func makeBuffers(device: MTLDevice){
        var size: Int
        size = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: size, options: [])
        
        size = textureCoordinateData.count * MemoryLayout<Float>.size
        texCoordBuffer = device.makeBuffer(bytes: textureCoordinateData, length: size, options: [])
    }
    
    func setupPipelineState(device: MTLDevice, view: MTKView) {
        guard let library = device.makeDefaultLibrary() else {
            return
        }
            
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        // ここを見直す
        descriptor.colorAttachments[0].pixelFormat = texture.pixelFormat
        pipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)
        
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        // ピクセルフォーマットを合わせる
        view.colorPixelFormat = texture.pixelFormat
        
        view.enableSetNeedsDisplay = true
        // ビューの更新依頼 → draw(in:)が呼ばれる
        view.setNeedsDisplay()
    }
    
    func draw(in view: MTKView) {
        
        guard let drawable = view.currentDrawable else {return}
        
        guard let cmdBuffer = self.commandQueue?.makeCommandBuffer() else {
            return
        }

        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        
        guard let encoder = cmdBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor) else {
            return
        }

        guard let renderPipeline = pipelineState else {fatalError()}
        encoder.setRenderPipelineState(renderPipeline)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        
        encoder.endEncoding()

        if let drawable = view.currentDrawable {
            cmdBuffer.present(drawable)
        }

        cmdBuffer.commit()
        
        // 完了まで待つ
        cmdBuffer.waitUntilCompleted()
    }
}
