//
//  CameraError.swift
//  RawCam
//
//  Created by Erdem Veziroğlu on 26.07.2025.
//

import Foundation

enum CameraError: Error {
    case permissionDenied
    case setupFailed
    case imageProcessingFailed
}

extension CameraError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera permission was denied. Please enable camera access in Settings."
        case .setupFailed:
            return "Failed to setup camera. Please try again."
        case .imageProcessingFailed:
            return "Failed to process captured image."
        }
    }
}