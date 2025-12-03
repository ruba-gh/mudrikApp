//
//  CameraView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi
//

import SwiftUI
import AVFoundation
import PhotosUI
import UniformTypeIdentifiers
import Combine
import ImageIO

struct CameraView: View {
    
    @StateObject private var camera = CameraManager()
    
    @State private var selectedImage: UIImage? = nil
    @State private var showCropView = false
    
    // For your pickers
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    
    // NEW: import popup
    @State private var showImportPopup = false
    
    // Text extracted from CropView
    @State private var extractedText: String = ""
    
    // State used by handleCameraTap (permission flow / legacy camera picker)
    @State private var showCamera = false
    @State private var cameraPermissionDenied = false
    @State private var showCameraPermissionAlert = false
    
    // Geometry of the whole view
    @State private var viewSize: CGSize = .zero

    // Data required by VideoPlayerView and LibraryView
    @State private var allSavedClips: [SavedClip] = []
    @State private var categories: [String] = ["المكتبة", "قصص", "مقابلات"]
    @State private var navigateToVideoPlayer = false
    @State private var navigateToLibrary = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let size = geo.size
                
                ZStack {
                    
                    // *** LIVE CAMERA FEED ***
                    CameraPreview(session: camera.session)
                        .ignoresSafeArea()
                        .onAppear { camera.startSession() }
                    
                    // ======= ORANGE BORDER BOX (GUIDE) =======
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.orange, lineWidth: 5)
                        .frame(width: size.width - 60, height: 350)
                        .padding(.top, 30) // lifted a little
                        .padding(.bottom, 140) // lifted a little
                    
                    VStack {
                        // ======= HEADER =======
                        VStack(spacing: 8) {
                            Text("التقط صورة للنص")
                                .font(.largeTitle)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            
                            Text("وجّه الكاميرا نحو النص المراد ترجمته إلى لغة الإشارة")
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.bottom, 30)
                            
                        }
                        .padding()
                        
                        
                        Spacer()
                        
                        // ===== IMPORT BUTTON =====
                        VStack(spacing: 12) {
                            AppButton(
                                title: "استيراد",
                                iconName: "square.and.arrow.down",
                                type: .systemWhite
                            ) {
                                showImportPopup = true
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 20)   // moves it up
                        
                        // ===== CAPTURE BUTTON =====
                        Button {
                            print("▶️ Capture button tapped")
                            camera.capturePhotoAsPNG { image in
                                guard let image = image else {
                                    print("⚠️ No image captured")
                                    return
                                }
                                
                                print("📸 Image captured size: \(image.size)")
                                
                                // Make sure we have a valid viewSize
                                guard viewSize.width > 0, viewSize.height > 0 else {
                                    print("⚠️ viewSize is zero, using full image")
                                    selectedImage = image
                                    showCropView = true
                                    return
                                }
                                
                                if let cropped = cropToOverlay(image: image, in: viewSize) {
                                    print("✅ Cropped image size: \(cropped.size)")
                                    selectedImage = cropped
                                } else {
                                    print("⚠️ Cropping failed, using full image")
                                    selectedImage = image
                                }
                                
                                showCropView = true
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(Color.orange, lineWidth: 5)
                                    .frame(width: 90, height: 90)
                                
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 70, height: 70)
                                    .glassEffect()
                                    .glassEffect(.regular.interactive())
                            }
                        }
                        
                        .padding(.bottom, 32)
                    }
                    
                    // ===== IMPORT POPUP OVERLAY =====
                    if showImportPopup {
                        Color.black.opacity(0.45)
                            .ignoresSafeArea()
                            .transition(.opacity)
                        
                        VStack {
                            VStack(spacing: 16) {
                                AppButton(
                                    title: "ألبوم الصور",
                                    iconName: "photo.on.rectangle",
                                    type: .orange
                                ) {
                                    showImportPopup = false
                                    showPhotoPicker = true
                                }
                                
                                AppButton(
                                    title: "الملفات",
                                    iconName: "folder",
                                    type: .systemWhite
                                ) {
                                    showImportPopup = false
                                    showFilePicker = true
                                }
                            }
                            .padding(20)
                            .background(Color.black)
                            .cornerRadius(24)
                        }
                        .padding(.horizontal, 24)
                        .transition(.scale)
                    }
                    
                    // NAVIGATE TO CROPVIEW
                    NavigationLink("", isActive: $showCropView) {
                        if let selectedImage {
                            CropView(image: selectedImage) { text in
                                // Called when user taps the check button in CropView
                                extractedText = text
                                print("📝 Extracted text: \(text)")
                                // Trigger navigation to VideoPlayerView
                                navigateToVideoPlayer = true
                            }
                        } else {
                            Color.black
                        }
                    }

                    // Hidden NavigationLink to VideoPlayerView
                    NavigationLink(
                        destination: VideoPlayerView(
                            extractedText: extractedText,
                            allSavedClips: $allSavedClips,
                            categories: $categories,
                            navigateToLibrary: $navigateToLibrary
                        ),
                        isActive: $navigateToVideoPlayer
                    ) {
                        EmptyView()
                    }
                    .hidden()

                    // Hidden NavigationLink to LibraryView (final destination)
                    NavigationLink(
                        destination: LibraryView(allClips: $allSavedClips, categories: $categories),
                        isActive: $navigateToLibrary
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
                .onAppear {
                    viewSize = size
                }
                .onChange(of: size) { newSize in
                    viewSize = newSize
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(image: $selectedImage)
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPickerView(selectedImage: $selectedImage, showCropView: $showCropView)
            }
            // Auto-navigate to Crop when user picks from photo/files
            .onChange(of: selectedImage) { img in
                if img != nil { showCropView = true }
            }
        }
    }
    
    // MARK: - Crop captured image to match the orange overlay
    private func cropToOverlay(image: UIImage, in viewSize: CGSize) -> UIImage? {
        
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }
        guard viewSize.width > 0, viewSize.height > 0 else { return nil }
        
        // 1) Define the orange box frame in VIEW coordinates
        let boxWidth = viewSize.width - 60
        let boxHeight: CGFloat = 350
        let boxTopPadding: CGFloat = 120   // keep in sync with padding above
        
        let originX = (viewSize.width - boxWidth) / 2
        let originY = (viewSize.height - boxHeight) / 2 + boxTopPadding
        
        let rectInView = CGRect(x: originX, y: originY, width: boxWidth, height: boxHeight)
        guard rectInView.width > 0, rectInView.height > 0 else {
            print("⚠️ rectInView has invalid size")
            return nil
        }
        
        // 2) How the camera image fills the view (.resizeAspectFill)
        let scale = max(viewSize.width / imageSize.width,
                        viewSize.height / imageSize.height)
        guard scale.isFinite, scale > 0 else {
            print("⚠️ Invalid scale \(scale)")
            return nil
        }
        
        let imageDisplaySize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        let offsetX = (viewSize.width - imageDisplaySize.width) / 2
        let offsetY = (viewSize.height - imageDisplaySize.height) / 2
        
        // 3) Convert from view coords → image coords
        let cropOriginX = (rectInView.origin.x - offsetX) / scale
        let cropOriginY = (rectInView.origin.y - offsetY) / scale
        let cropWidth = rectInView.size.width / scale
        let cropHeight = rectInView.size.height / scale
        
        var cropRect = CGRect(
            x: cropOriginX,
            y: cropOriginY,
            width: cropWidth,
            height: cropHeight
        )
        
        // 4) Clamp to image bounds & validate
        let imageRect = CGRect(origin: .zero, size: imageSize)
        if !imageRect.intersects(cropRect) {
            print("⚠️ cropRect does not intersect imageRect")
            return nil
        }
        
        cropRect = cropRect.intersection(imageRect)
        
        guard
            cropRect.width > 0,
            cropRect.height > 0,
            cropRect.origin.x.isFinite,
            cropRect.origin.y.isFinite,
            cropRect.size.width.isFinite,
            cropRect.size.height.isFinite
        else {
            print("⚠️ cropRect invalid after intersection: \(cropRect)")
            return nil
        }
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            print("⚠️ cgImage cropping failed")
            return nil
        }
        
        return UIImage(
            cgImage: cgImage,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }
    
    // MARK: - Camera Permission + Open Camera (kept for future use)
    private func handleCameraTap() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showCamera = true
                    } else {
                        self.cameraPermissionDenied = true
                        self.showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            cameraPermissionDenied = true
            showCameraPermissionAlert = true
        @unknown default:
            cameraPermissionDenied = true
            showCameraPermissionAlert = true
        }
    }
}

/////////////////////////////////////////////////
// MARK: - PhotoPicker
/////////////////////////////////////////////////

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(
        _ uiViewController: PHPickerViewController,
        context: Context
    ) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self)
            else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = (image as? UIImage)?.normalizedUp()
                }
            }
        }
    }
}

/////////////////////////////////////////////////
// MARK: - DocumentPickerView
/////////////////////////////////////////////////

struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var showCropView: Bool
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: Context
    ) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            guard let url = urls.first else { return }
            
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                parent.selectedImage = image.normalizedUp()
                parent.showCropView = true
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            controller.dismiss(animated: true)
        }
    }
}

/////////////////////////////////////////////////
// MARK: - UIImage Orientation Fix
/////////////////////////////////////////////////

extension UIImage {
    func normalizedUp() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

/////////////////////////////////////////////////
// MARK: - CameraPreview
/////////////////////////////////////////////////

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

/////////////////////////////////////////////////
// MARK: - CameraManager
/////////////////////////////////////////////////

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "camera.queue")
    
    // IMPORTANT: keep delegate alive
    private var photoDelegate: PhotoDelegate?
    
    override init() {
        super.init()
        configure()
    }
    
    private func configure() {
        session.beginConfiguration()
        
        // Camera device
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back)
        else {
            session.commitConfiguration()
            return
        }
        
        // Input
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Output
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
    }
    
    func startSession() {
        queue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    // Capture and return a UIImage (PNG pipeline) with a retained delegate
    func capturePhotoAsPNG(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        
        let delegate = PhotoDelegate { [weak self] image in
            guard let self = self else { return }
            
            // Re-encode as PNG to keep consistent pipeline, but don't crash if it fails
            if let img = image,
               let pngData = img.pngData(),
               let pngImage = UIImage(data: pngData) {
                DispatchQueue.main.async {
                    completion(pngImage.normalizedUp())
                }
            } else {
                DispatchQueue.main.async {
                    completion(image?.normalizedUp())
                }
            }
            
            // Release delegate after capture completes
            self.photoDelegate = nil
        }
        
        self.photoDelegate = delegate
        output.capturePhoto(with: settings, delegate: delegate)
    }
}

/////////////////////////////////////////////////
// MARK: - PhotoDelegate
/////////////////////////////////////////////////

class PhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let handler: (UIImage?) -> Void
    init(_ handler: @escaping (UIImage?) -> Void) { self.handler = handler }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("Photo capture error: \(error)")
            handler(nil)
            return
        }
        
        // Use cgImageRepresentation for best fidelity, then construct UIImage
        if let cgImage = photo.cgImageRepresentation() {
            let orientation = UIImage.Orientation.fromExif(photo.metadata)
            let image = UIImage(cgImage: cgImage, scale: 1, orientation: orientation)
            handler(image)
            return
        }
        
        // Fallback
        if let data = photo.fileDataRepresentation(),
           let image = UIImage(data: data) {
            handler(image)
        } else {
            handler(nil)
        }
    }
}

/////////////////////////////////////////////////
// MARK: - UIImage.Orientation from EXIF
/////////////////////////////////////////////////

private extension UIImage.Orientation {
    static func fromExif(_ metadata: [AnyHashable: Any]) -> UIImage.Orientation {
        if let value = metadata[kCGImagePropertyOrientation as String] as? NSNumber {
            switch value.intValue {
            case 1: return .up
            case 3: return .down
            case 6: return .right
            case 8: return .left
            case 2: return .upMirrored
            case 4: return .downMirrored
            case 5: return .leftMirrored
            case 7: return .rightMirrored
            default: return .right
            }
        }
        return .right
    }
}

#Preview {
    CameraView()
}
