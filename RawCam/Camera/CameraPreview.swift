//
//  CameraPreview.swift
//  RawCam
//
//  Created by Erdem Veziroğlu on 15.05.2025.
//
import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view: UIView = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        print("🎥 CameraPreview - Session isRunning: \(session.isRunning)")
        print("🎥 CameraPreview - Session inputs count: \(session.inputs.count)")
        print("🎥 CameraPreview - Session outputs count: \(session.outputs.count)")
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                layer.frame = uiView.bounds
                print("🔄 CameraPreview - Layer frame updated: \(uiView.bounds)")
                
                if uiView.bounds.width == 0 || uiView.bounds.height == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        layer.frame = uiView.bounds
                        print("🔄 CameraPreview - Layer frame retry: \(uiView.bounds)")
                    }
                }
            }
        }
    }
}

struct CameraPreviewAlternative: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        return CameraPreviewUIView(session: session)
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
    }
}

class CameraPreviewUIView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer
    
    init(session: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)
        setupPreviewLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPreviewLayer() {
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        print("🎥 CameraPreviewUIView - Preview layer setup completed")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        print("🔄 CameraPreviewUIView - Layout updated: \(bounds)")
    }
}
