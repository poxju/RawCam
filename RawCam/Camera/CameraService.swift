//
//  CameraService.swift
//  RawCam
//
//  Created by Erdem Veziroğlu on 15.05.2025.
//

import AVFoundation
import UIKit

class CameraService: ObservableObject {
    let session: AVCaptureSession
    private var photoOutput: AVCapturePhotoOutput
    private var currentCamera: AVCaptureDevice?
    private var currentPosition: AVCaptureDevice.Position = .back
    
    @MainActor @Published var hasPermission = false
    @MainActor @Published var isSessionRunning = false
    
    private var isFlashOn = false
    private var isConfigured = false
    
    init() {
        self.session = AVCaptureSession()
        self.photoOutput = AVCapturePhotoOutput()
    }
    
    func configure() async throws {
        guard !isConfigured else {
            print("🚫 CameraService - Already configured, skipping")
            return
        }
        
        print("🔄 CameraService - Starting configuration...")
        
        let hasAccess = await AVCaptureDevice.requestAccess(for: .video)
        print("📱 CameraService - Camera permission: \(hasAccess)")
        
        await MainActor.run {
            self.hasPermission = hasAccess
        }
        
        guard hasAccess else {
            print("❌ CameraService - Permission denied")
            throw CameraError.permissionDenied
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    print("❌ CameraService - Self is nil")
                    continuation.resume(throwing: CameraError.setupFailed)
                    return
                }
                
                do {
                    print("🔧 CameraService - Beginning session configuration...")
                    self.session.beginConfiguration()
                    
                    // Setup input
                    guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                        print("❌ CameraService - No back camera found")
                        continuation.resume(throwing: CameraError.setupFailed)
                        return
                    }
                    
                    print("📷 CameraService - Found camera: \(camera.localizedName)")
                    
                    guard let input = try? AVCaptureDeviceInput(device: camera) else {
                        print("❌ CameraService - Failed to create camera input")
                        continuation.resume(throwing: CameraError.setupFailed)
                        return
                    }
                    
                    self.currentCamera = camera
                    if self.session.canAddInput(input) {
                        self.session.addInput(input)
                        print("✅ CameraService - Camera input added")
                    } else {
                        print("❌ CameraService - Cannot add camera input")
                        continuation.resume(throwing: CameraError.setupFailed)
                        return
                    }
                    
                    // Setup output
                    if self.session.canAddOutput(self.photoOutput) {
                        self.session.addOutput(self.photoOutput)
                        print("✅ CameraService - Photo output added")
                    } else {
                        print("❌ CameraService - Cannot add photo output")
                    }
                    
                    self.session.sessionPreset = .photo
                    print("🔧 CameraService - Session preset set to photo")
                    
                    self.session.commitConfiguration()
                    print("✅ CameraService - Configuration committed")
                    
                    self.session.startRunning()
                    print("🎬 CameraService - Session started running: \(self.session.isRunning)")
                    
                    Task { @MainActor in
                        self.isSessionRunning = true
                        self.isConfigured = true
                        print("✅ CameraService - UI state updated: isSessionRunning = true")
                    }
                    
                    continuation.resume()
                } catch {
                    print("❌ CameraService - Configuration error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func capturePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate(completion: completion))
    }
    
    func switchCamera() {
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        
        session.beginConfiguration()
        session.removeInput(currentInput)
        
        currentPosition = currentPosition == .back ? .front : .back
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
            session.commitConfiguration()
            return
        }
        
        currentCamera = newCamera
        if session.canAddInput(newInput) {
            session.addInput(newInput)
        }
        
        session.commitConfiguration()
    }
    
    func toggleFlash(_ isOn: Bool) {
        isFlashOn = isOn
    }
}
