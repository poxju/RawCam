//
//  CameraView.swift
//  RawCam
//
//  Created by Erdem Veziroğlu on 15.05.2025.
//
import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraService = CameraService()
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var capturedImage: UIImage?
    @State private var isFlashOn = false
    
    // Camera parameter states - ranges from 0.0 to 1.0
    // These would map to real values: SS (1/8000s to 2s), Aperture (f/1.4 to f/16), ISO (100 to 6400)
    @State private var shutterSpeedValue: Double = 0.5  // Maps to ~1/125s
    @State private var apertureValue: Double = 0.3      // Maps to ~f/2.8
    @State private var isoValue: Double = 0.2           // Maps to ~ISO 400
    
    // Mode dial state
    @State private var selectedMode: CameraMode = .ai
    
    var body: some View {
        ZStack {
            // Camera preview background
            Color.black.ignoresSafeArea()
            
            // Camera preview - only show when session is running
            if cameraService.isSessionRunning {
                CameraPreviewAlternative(session: cameraService.session)
                    .ignoresSafeArea()
                    .overlay(
                        capturedImage != nil ?
                            Image(uiImage: capturedImage!)
                                .resizable()
                                .scaledToFit()
                                .ignoresSafeArea()
                            : nil
                    )
            }
            
            // UI Controls - daha basit ve düzenli layout
            VStack {
                Spacer()
                
                // Bottom UI Area
                VStack(spacing: 30) {
                    // ISO Slider - en üstte
                    isoSlider
                    
                    // Control Row - flash, mode, shutter
                    HStack {
                        // Flash Button
                        Button(action: {
                            isFlashOn.toggle()
                            cameraService.toggleFlash(isFlashOn)
                        }) {
                            Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Mode Selection - kaydırılabilir buton
                        ModeSliderButton(selectedMode: $selectedMode)
                        
                        Spacer()
                        
                        // Shutter Button
                        Button(action: capturePhoto) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                Circle()
                                    .stroke(Color.yellow, lineWidth: 4)
                                    .frame(width: 80, height: 80)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 50)
            }
            
            // Side Sliders - sadece gerekli modlarda göster
            if selectedMode.availableControls.contains(.shutterSpeed) {
                HStack {
                    shutterSpeedSlider
                        .padding(.leading, 10)
                    Spacer()
                }
            }
            
            if selectedMode.availableControls.contains(.aperture) {
                HStack {
                    Spacer()
                    apertureSlider
                        .padding(.trailing, 10)
                }
            }
        }
        .onAppear {
            Task {
                do {
                    try await cameraService.configure()
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
        .alert("Camera Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .overlay(permissionOverlay)
    }
    
    // MARK: - UI Components - Simplyfied
    
    private var shutterSpeedSlider: some View {
        VStack {
            Text("SS")
                .font(.caption)
                .foregroundColor(.white)
            
            VStack {
                Text(formatShutterSpeed(shutterSpeedValue))
                    .font(.caption2)
                    .foregroundColor(.yellow)
                    .frame(height: 20)
                
                Slider(value: $shutterSpeedValue, in: 0...1)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 180)
                    .accentColor(.yellow)
            }
            .frame(height: 220)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.5))
                .frame(width: 50)
        )
    }
    
    private var apertureSlider: some View {
        VStack {
            Text("A")
                .font(.caption)
                .foregroundColor(.white)
            
            VStack {
                Text(formatAperture(apertureValue))
                    .font(.caption2)
                    .foregroundColor(.yellow)
                    .frame(height: 20)
                
                Slider(value: $apertureValue, in: 0...1)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 180)
                    .accentColor(.yellow)
            }
            .frame(height: 220)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.5))
                .frame(width: 50)
        )
    }
    
    private var isoSlider: some View {
        VStack(spacing: 8) {
            Text("ISO")
                .font(.caption)
                .foregroundColor(.white)
            
            HStack {
                Text(formatISO(isoValue))
                    .font(.caption2)
                    .foregroundColor(.yellow)
                    .frame(width: 80)
                
                Slider(value: $isoValue, in: 0...1)
                    .accentColor(.yellow)
                
                Spacer()
                    .frame(width: 80)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.5))
        )
        .padding(.horizontal, 40)
    }
    
    // MARK: - Main UI Components
    
    private var permissionOverlay: some View {
        Group {
            if !cameraService.hasPermission {
                VStack {
                    Text("Camera access is required")
                        .foregroundColor(.white)
                        .padding()
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .background(Color.black.opacity(0.8))
                .cornerRadius(10)
                .padding()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func capturePhoto() {
        cameraService.capturePhoto { result in
            switch result {
            case .success(let image):
                capturedImage = image
                // Auto-dismiss preview after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    capturedImage = nil
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    // Format slider values to realistic camera settings
    private func formatShutterSpeed(_ value: Double) -> String {
        // Map 0.0-1.0 to 1/8000s - 2s
        let speeds = ["1/8000", "1/4000", "1/2000", "1/1000", "1/500", "1/250", "1/125", "1/60", "1/30", "1/15", "1/8", "1/4", "1/2", "1", "2"]
        let index = Int(value * Double(speeds.count - 1))
        return speeds[min(index, speeds.count - 1)]
    }
    
    private func formatAperture(_ value: Double) -> String {
        // Map 0.0-1.0 to f/1.4 - f/16
        let apertures = ["f/1.4", "f/1.8", "f/2.0", "f/2.8", "f/4.0", "f/5.6", "f/8.0", "f/11", "f/16"]
        let index = Int(value * Double(apertures.count - 1))
        return apertures[min(index, apertures.count - 1)]
    }
    
    private func formatISO(_ value: Double) -> String {
        // Map 0.0-1.0 to ISO 100 - 6400
        let isoValue = Int(100 + (value * 6300))
        return "ISO \(isoValue)"
    }
}

// MARK: - Mode Button

struct ModeSliderButton: View {
    @Binding var selectedMode: CameraMode
    @State private var dragOffset: CGFloat = 0
    
    private let modes: [CameraMode] = CameraMode.allCases
    private let buttonWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Arka plan
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black.opacity(0.6))
                .frame(width: buttonWidth, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.yellow, lineWidth: 2)
                )
            
            // Mode text
            Text(selectedMode.rawValue)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.yellow)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 30
                    
                    if value.translation.width > threshold {
                        // Sağa kaydırma - sonraki mod
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMode = selectedMode.next
                        }
                    } else if value.translation.width < -threshold {
                        // Sola kaydırma - önceki mod
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if let currentIndex = modes.firstIndex(of: selectedMode) {
                                let previousIndex = currentIndex > 0 ? currentIndex - 1 : modes.count - 1
                                selectedMode = modes[previousIndex]
                            }
                        }
                    }
                    
                    withAnimation(.easeInOut(duration: 0.2)) {
                        dragOffset = 0
                    }
                }
        )
        .offset(x: dragOffset * 0.1)
        .animation(.easeInOut(duration: 0.2), value: selectedMode)
    }
}
