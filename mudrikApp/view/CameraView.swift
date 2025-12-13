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

    // Use the shared store instead of local arrays
    @EnvironmentObject var store: ClipsStore

    // Navigation flags
    @State private var navigateToVideoPlayer = false
    @State private var navigateToLibrary = false
    private let guideYOffset: CGFloat = -100

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
                    let guide = boxRect(in: size).offsetBy(dx: 0, dy: guideYOffset)

                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.orange, lineWidth: 5)
                        .frame(width: guide.width, height: guide.height)
                        .position(x: guide.midX, y: guide.midY)

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
                        .padding(.bottom, 20)

                        // ===== CAPTURE BUTTON =====
                        Button {
                            print("▶️ Capture button tapped")
                            camera.capturePhotoForOCR { image in
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

                                // Use the exact same rect used to draw the orange guide
                                let rectOnScreen = boxRect(in: viewSize).offsetBy(dx: 0, dy: guideYOffset)

                                if let cropped = crop(image: image, viewSize: viewSize, rectOnScreen: rectOnScreen) {
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
                            allSavedClips: $store.clips,
                            categories: $store.categories,
                            navigateToLibrary: $navigateToLibrary
                        ),
                        isActive: $navigateToVideoPlayer
                    ) {
                        EmptyView()
                    }
                    .hidden()

                    // Hidden NavigationLink to LibraryView (final destination)
                    NavigationLink(
                        destination: LibraryView(allClips: $store.clips, categories: $store.categories),
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

    // MARK: - Single source of truth for the orange guide rect on screen
    private func boxRect(in viewSize: CGSize) -> CGRect {
        // Keep the same visual as before: width = view width - 60, height = 350
        // Previously you used padding; here we compute explicit position.
        let width = max(0, viewSize.width - 60)
        let height: CGFloat = 350

        // Center vertically, then nudge down to roughly match your prior padding combo
        // You can tweak offsetY to fine-tune if needed.
        let centerY = viewSize.height / 2
        let offsetY: CGFloat = 50 // tuned to visually match previous layout
        let originX = (viewSize.width - width) / 2
        let originY = centerY - (height / 2) + offsetY

        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    // MARK: - Crop using the guide rect and the preview's aspect fill
    private func crop(image: UIImage, viewSize: CGSize, rectOnScreen: CGRect) -> UIImage? {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }
        guard viewSize.width > 0, viewSize.height > 0 else { return nil }

        // AVCaptureVideoPreviewLayer uses .resizeAspectFill
        let scale = max(viewSize.width / imageSize.width,
                        viewSize.height / imageSize.height)
        guard scale.isFinite, scale > 0 else { return nil }

        let imageDisplaySize = CGSize(width: imageSize.width * scale,
                                      height: imageSize.height * scale)
        let offsetX = (viewSize.width - imageDisplaySize.width) / 2
        let offsetY = (viewSize.height - imageDisplaySize.height) / 2

        // Convert from view coords → image coords
        let cropOriginX = (rectOnScreen.origin.x - offsetX) / scale
        let cropOriginY = (rectOnScreen.origin.y - offsetY) / scale
        let cropWidth = rectOnScreen.size.width / scale
        let cropHeight = rectOnScreen.size.height / scale

        var cropRect = CGRect(x: cropOriginX, y: cropOriginY, width: cropWidth, height: cropHeight)

        // Clamp and validate
        let imageRect = CGRect(origin: .zero, size: imageSize)
        if !imageRect.intersects(cropRect) {
            return nil
        }
        cropRect = cropRect.intersection(imageRect)
        guard cropRect.width > 0, cropRect.height > 0 else { return nil }

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return nil }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
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

#Preview {
    CameraView()
        .environmentObject(ClipsStore())
}
