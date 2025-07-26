//
//  CameraMode.swift
//  RawCam
//
//  Created by Erdem Veziroğlu on 16.05.2025.
//

import Foundation

enum CameraMode: String, CaseIterable {
    case ai = "AI+"
    case p = "P"
    case a = "A"
    case s = "S"
    case m = "M"

    var next: CameraMode {
        guard let index = CameraMode.allCases.firstIndex(of: self) else {
            return .ai
        }
        let nextIndex = (index + 1) % CameraMode.allCases.count
        return CameraMode.allCases[nextIndex]
    }
    
    var description: String {
        switch self {
        case .ai:
            return "AI Helper Mode"
        case .p:
            return "Program Mode"
        case .a:
            return "Aperture Priority"
        case .s:
            return "Shutter Priority"
        case .m:
            return "Manual Mode"
        }
    }
    
    var availableControls: [CameraControl] {
        switch self {
        case .ai:
            return [.exposureCompensation]
        case .p:
            return [.exposureCompensation, .iso]
        case .a:
            return [.aperture, .iso, .exposureCompensation]
        case .s:
            return [.shutterSpeed, .iso, .exposureCompensation]
        case .m:
            return [.aperture, .shutterSpeed, .iso]
        }
    }
    
    var iconName: String {
        switch self {
        case .ai:
            return "brain.head.profile"
        case .p:
            return "p.circle"
        case .a:
            return "a.circle"
        case .s:
            return "s.circle"
        case .m:
            return "m.circle"
        }
    }
}

enum CameraControl: String, CaseIterable {
    case aperture = "Aperture"
    case shutterSpeed = "Shutter Speed"
    case iso = "ISO"
    case exposureCompensation = "Exposure Compensation"
    
    var unit: String {
        switch self {
        case .aperture:
            return "f/"
        case .shutterSpeed:
            return "s"
        case .iso:
            return "ISO"
        case .exposureCompensation:
            return "E"
        }
    }
}
