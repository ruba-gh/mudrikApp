import Foundation
import AVFoundation
import UIKit
import Combine
import UniformTypeIdentifiers
import ImageIO

final class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "CameraManager.SessionQueue")
    private let photoOutput = AVCapturePhotoOutput()

    private var isConfigured = false
    private var shouldStartAfterConfigure = false   // ✅ important

    override init() {
        super.init()
        requestAuthorizationAndConfigure()
    }

    private func requestAuthorizationAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSessionIfNeeded(startAfter: true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.configureSessionIfNeeded(startAfter: true)
                } else {
                    print("⚠️ Camera access denied")
                }
            }
        case .denied, .restricted:
            print("⚠️ Camera access denied/restricted")
        @unknown default:
            print("⚠️ Unknown camera auth status")
        }
    }

    private func configureSessionIfNeeded(startAfter: Bool) {
        sessionQueue.async {
            if startAfter { self.shouldStartAfterConfigure = true }
            guard !self.isConfigured else {
                if self.shouldStartAfterConfigure { self.startSession() }
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                self.session.commitConfiguration()
                print("⚠️ No back camera")
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    self.session.commitConfiguration()
                    print("⚠️ Can't add input")
                    return
                }
            } catch {
                self.session.commitConfiguration()
                print("⚠️ Input error: \(error)")
                return
            }

            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
            } else {
                self.session.commitConfiguration()
                print("⚠️ Can't add output")
                return
            }

            self.session.commitConfiguration()
            self.isConfigured = true

            // ✅ if view already asked to start, start now
            if self.shouldStartAfterConfigure {
                self.startSession()
            }
        }
    }

    func startSession() {
        sessionQueue.async {
            // ✅ if not configured yet, request and remember intent
            guard self.isConfigured else {
                self.configureSessionIfNeeded(startAfter: true)
                return
            }
            guard !self.session.isRunning else { return }

            self.session.startRunning()
            DispatchQueue.main.async { self.isSessionRunning = true }
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isSessionRunning = false }
        }
    }

    func capturePhotoForOCR(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true

        let delegate = PhotoCaptureDelegateForUIImage { image in
            completion(image)
        }

        PhotoCaptureDelegateForUIImage.retain(delegate)

        sessionQueue.async {
            guard self.session.isRunning else {
                print("⚠️ capturePhotoForOCR called but session is NOT running")
                DispatchQueue.main.async { completion(nil) }
                PhotoCaptureDelegateForUIImage.release(delegate)
                return
            }
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
}


private final class PhotoCaptureDelegateForUIImage: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void

    // ✅ actually retains the object
    private static var active: [ObjectIdentifier: PhotoCaptureDelegateForUIImage] = [:]
    private static let lock = NSLock()

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    static func retain(_ delegate: PhotoCaptureDelegateForUIImage) {
        lock.lock(); defer { lock.unlock() }
        active[ObjectIdentifier(delegate)] = delegate
    }

    static func release(_ delegate: PhotoCaptureDelegateForUIImage) {
        lock.lock(); defer { lock.unlock() }
        active.removeValue(forKey: ObjectIdentifier(delegate))
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("⚠️ Photo capture error: \(error)")
            completion(nil)
            return
        }

        if let data = photo.fileDataRepresentation(), let img = UIImage(data: data) {
            completion(img)
            return
        }

        if let cg = photo.cgImageRepresentation() {
            completion(UIImage(cgImage: cg, scale: 1.0, orientation: .right))
            return
        }

        completion(nil)
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {
        PhotoCaptureDelegateForUIImage.release(self)
    }
}

    // Helper to safely get CGImage and orientation using modern API
    private func makeUIImageFromCGImageRepresentation(photo: AVCapturePhoto) -> UIImage? {
        if let cgImage = photo.cgImageRepresentation() {
            let orientation = uiImageOrientation(from: photo)
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
        }
        return nil
    }

    private func uiImageOrientation(from photo: AVCapturePhoto) -> UIImage.Orientation {
        // Try to read EXIF orientation from metadata
        if let orientationValue = photo.metadata[kCGImagePropertyOrientation as String] as? NSNumber,
           let exif = CGImagePropertyOrientation(rawValue: orientationValue.uint32Value) {
            return UIImage.Orientation(exif)
        }

        // Fallback: typical back camera in portrait
        return .right
    }


// MARK: - Utility to map EXIF orientation to UIImage.Orientation
private extension UIImage.Orientation {
    init(_ exifOrientation: CGImagePropertyOrientation) {
        switch exifOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
