//
//  PhotoCaptureDelegate.swift
//  RawCam
//
//  Created by Erdem Veziroğlu on 26.07.2025.
//

import AVFoundation
import UIKit

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<UIImage, Error>) -> Void
    
    init(completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(.failure(CameraError.imageProcessingFailed))
            return
        }
        
        completion(.success(image))
    }
}
