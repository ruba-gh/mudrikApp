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

    // Pickers
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false

    // UIKit alert config (replaces custom import popup)
    @State private var alertConfig: AlertConfig? = nil

    // Text extracted
    @State private var extractedText: String = ""

    // Geometry
    @State private var viewSize: CGSize = .zero

    // Shared store
    @EnvironmentObject var store: ClipsStore

    // Navigation flags
    @State private var navigateToVideoPlayer = false
    @State private var navigateToLibrary = false

    // Guide offset
    private let guideYOffset: CGFloat = -100

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let size = geo.size

                ZStack {
                    // LIVE CAMERA FEED
                    CameraPreview(session: camera.session)
                        .ignoresSafeArea()
                        .onAppear { camera.startSession() }

                    // ORANGE GUIDE (same rect used for cropping)
                    let guide = boxRect(in: size).offsetBy(dx: 0, dy: guideYOffset)

                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.orange, lineWidth: 5)
                        .frame(width: guide.width, height: guide.height)
                        .position(x: guide.midX, y: guide.midY)

                    VStack {
                        Spacer()

                        // IMPORT BUTTON
                        VStack(spacing: 12) {
                            AppButton(
                                title: "استيراد",
                                iconName: "square.and.arrow.down",
                                type: .systemWhite
                            ) {
                                presentImportAlert()
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 20)

                        // CAPTURE BUTTON
                        Button {
                            print("▶️ Capture button tapped")

                            camera.capturePhotoForOCR { image in
                                guard let image else {
                                    print("⚠️ No image captured")
                                    return
                                }

                                DispatchQueue.main.async {
                                    print("📸 Image captured size: \(image.size)")

                                    // If viewSize is not ready, fallback to full image
                                    guard viewSize.width > 0, viewSize.height > 0 else {
                                        print("⚠️ viewSize is zero, using full image")
                                        selectedImage = image
                                        showCropView = true
                                        return
                                    }

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

                    // NAVIGATE TO CROP (WITH ALERT ON THE DESTINATION SCREEN)
                    NavigationLink("", isActive: $showCropView) {
                        if let selectedImage {
                            CropView(image: selectedImage) { validArabicText in
                                extractedText = validArabicText
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

                    // Hidden NavigationLink to LibraryView
                    NavigationLink(
                        destination: LibraryView(store: store),
                        isActive: $navigateToLibrary
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
                .onAppear { viewSize = size }
                .onChange(of: size) { viewSize = $0 }
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
            .systemAlert(config: $alertConfig)
            .navigationTitle("التقط صورة للنص")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("التقط صورة للنص")
                            .font(.headline)
                        Text("وجّه الكاميرا نحو النص المراد ترجمته إلى لغة الإشارة")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }

    private func presentImportAlert() {
        alertConfig = AlertConfig(
            title: "استيراد من",
            message: nil,
            preferredStyle: .alert, // centered on iPhone
            textFields: [],
            actions: [
                AlertAction("ألبوم الصور", style: .default, handler: {
                    showPhotoPicker = true
                }),
                AlertAction("الملفات", style: .default, handler: {
                    showFilePicker = true
                }),
                AlertAction("إلغاء", style: .cancel, handler: nil)
            ]
        )
    }

    // MARK: - Guide rect (single source of truth)
    private func boxRect(in viewSize: CGSize) -> CGRect {
        let width = max(0, viewSize.width - 60)
        let height: CGFloat = 350

        let centerY = viewSize.height / 2
        let offsetY: CGFloat = 50

        let originX = (viewSize.width - width) / 2
        let originY = centerY - (height / 2) + offsetY

        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    // MARK: - Crop to what is inside the guide box
    private func crop(image: UIImage, viewSize: CGSize, rectOnScreen: CGRect) -> UIImage? {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }
        guard viewSize.width > 0, viewSize.height > 0 else { return nil }

        // preview uses .resizeAspectFill
        let scale = max(viewSize.width / imageSize.width,
                        viewSize.height / imageSize.height)
        guard scale.isFinite, scale > 0 else { return nil }

        let imageDisplaySize = CGSize(width: imageSize.width * scale,
                                      height: imageSize.height * scale)
        let offsetX = (viewSize.width - imageDisplaySize.width) / 2
        let offsetY = (viewSize.height - imageDisplaySize.height) / 2

        // View coords -> Image coords
        let cropOriginX = (rectOnScreen.origin.x - offsetX) / scale
        let cropOriginY = (rectOnScreen.origin.y - offsetY) / scale
        let cropWidth = rectOnScreen.size.width / scale
        let cropHeight = rectOnScreen.size.height / scale

        var cropRect = CGRect(x: cropOriginX, y: cropOriginY, width: cropWidth, height: cropHeight)

        // Clamp
        let imageRect = CGRect(origin: .zero, size: imageSize)
        guard imageRect.intersects(cropRect) else { return nil }
        cropRect = cropRect.intersection(imageRect)
        guard cropRect.width > 0, cropRect.height > 0 else { return nil }

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
