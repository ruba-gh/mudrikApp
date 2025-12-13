//
//  CropView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 10/06/1447 AH.
//

import SwiftUI
import Vision

struct CropView: View {
    let image: UIImage
    let onTextExtracted: (String) -> Void

    // ✅ IMPORTANT: normalize the image so what user sees == what we crop == what OCR reads
    private var normalizedImage: UIImage { image.normalizedUp() }

    // State used when dragging the entire crop rectangle
    @State private var dragStartRect: CGRect = .zero
    @State private var isDraggingRect = false

    // State used when dragging individual corner handles
    @State private var cornerDragStartRect: CGRect = .zero
    @State private var activeCorner: Corner? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var isProcessing = false
    @State private var errorMessage: String?

    // The frame where the image is actually rendered inside the 360pt area
    @State private var imageFrame: CGRect = .zero

    // Crop rectangle in view coordinates (always constrained to imageFrame)
    @State private var cropRect: CGRect = .zero
    @State private var didInitCrop = false

    // For debugging: show the recognized text on screen
    @State private var extractedTextPreview: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("قص النص")
                .font(.largeTitle)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text("اضبط الإطار إلى الحجم المطلوب")
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, 30)

            GeometryReader { _ in
                ZStack {
                    Color(.systemBackground)

                    // 1) Render the image with aspect-fit and capture its frame
                    GeometryReader { innerGeo in
                        let viewSize = innerGeo.size
                        let frame = aspectFitFrame(
                            imageSize: normalizedImage.size,
                            in: viewSize
                        )

                        Color.clear
                            .onAppear {
                                setupFramesIfNeeded(imageFrame: frame)
                            }
                            .onChange(of: innerGeo.size) { _ in
                                // When layout changes, recompute imageFrame & keep cropRect relative
                                let oldFrame = imageFrame
                                imageFrame = frame

                                if oldFrame != .zero && cropRect != .zero {
                                    let relX = (cropRect.minX - oldFrame.minX) / oldFrame.width
                                    let relY = (cropRect.minY - oldFrame.minY) / oldFrame.height
                                    let relW = cropRect.width / oldFrame.width
                                    let relH = cropRect.height / oldFrame.height

                                    let newX = imageFrame.minX + relX * imageFrame.width
                                    let newY = imageFrame.minY + relY * imageFrame.height
                                    let newW = relW * imageFrame.width
                                    let newH = relH * imageFrame.height

                                    cropRect = clampRect(
                                        CGRect(x: newX, y: newY, width: newW, height: newH),
                                        inside: imageFrame
                                    )
                                }
                            }

                        Image(uiImage: normalizedImage) // ✅ show normalized
                            .resizable()
                            .scaledToFit()
                            .frame(width: frame.width, height: frame.height)
                            .position(x: frame.midX, y: frame.midY)
                    }

                    if imageFrame != .zero {
                        // Dim outside crop
                        overlayOutsideCrop()

                        // Crop rectangle + handles
                        cropRectangle()
                    }
                }
            }
            .frame(height: 360)

            if isProcessing {
                ProgressView("جاري قراءة النص...")
            }

            if !extractedTextPreview.isEmpty {
                Text("النص المستخرج (تجريبي):")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView {
                    Text(extractedTextPreview)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 160)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            HStack {
                Spacer()
                RoundOrangeButton(size: 70, icon: "checkmark") {
                    runOcrOnCrop()
                }
                .padding()
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Setup

    private func setupFramesIfNeeded(imageFrame: CGRect) {
        guard !didInitCrop else { return }
        didInitCrop = true

        self.imageFrame = imageFrame

        // Initialize crop slightly inset
        let inset: CGFloat = 24
        cropRect = imageFrame.insetBy(dx: inset, dy: inset)
    }

    private func aspectFitFrame(imageSize: CGSize, in container: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = container.width / container.height

        var size = CGSize.zero

        if imageAspect > containerAspect {
            size.width = container.width
            size.height = container.width / imageAspect
        } else {
            size.height = container.height
            size.width = container.height * imageAspect
        }

        let origin = CGPoint(
            x: (container.width - size.width) / 2,
            y: (container.height - size.height) / 2
        )

        return CGRect(origin: origin, size: size)
    }

    // MARK: - Crop rect UI

    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private func cropRectangle() -> some View {
        let rect = cropRect

        return Rectangle()
            .path(in: rect)
            .stroke(Color.orange, lineWidth: 3)
            .contentShape(Rectangle().path(in: rect))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDraggingRect {
                            isDraggingRect = true
                            dragStartRect = cropRect
                        }

                        var new = dragStartRect.offsetBy(
                            dx: value.translation.width,
                            dy: value.translation.height
                        )

                        new = clampRect(new, inside: imageFrame)
                        cropRect = new
                    }
                    .onEnded { _ in
                        isDraggingRect = false
                    }
            )
            .overlay(
                ZStack {
                    cornerHandle(.topLeft)
                    cornerHandle(.topRight)
                    cornerHandle(.bottomLeft)
                    cornerHandle(.bottomRight)
                }
            )
    }

    private func cornerHandle(_ corner: Corner) -> some View {
        let point: CGPoint
        switch corner {
        case .topLeft:
            point = CGPoint(x: cropRect.minX, y: cropRect.minY)
        case .topRight:
            point = CGPoint(x: cropRect.maxX, y: cropRect.minY)
        case .bottomLeft:
            point = CGPoint(x: cropRect.minX, y: cropRect.maxY)
        case .bottomRight:
            point = CGPoint(x: cropRect.maxX, y: cropRect.maxY)
        }

        return Circle()
            .fill(Color.orange)
            .frame(width: 18, height: 18)
            .position(point)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if activeCorner == nil {
                            activeCorner = corner
                            cornerDragStartRect = cropRect
                        }

                        var new = cornerDragStartRect
                        let minSize: CGFloat = 60

                        switch corner {
                        case .topLeft:
                            new.origin.x += value.translation.width
                            new.origin.y += value.translation.height
                            new.size.width  -= value.translation.width
                            new.size.height -= value.translation.height

                        case .topRight:
                            new.origin.y += value.translation.height
                            new.size.width  += value.translation.width
                            new.size.height -= value.translation.height

                        case .bottomLeft:
                            new.origin.x += value.translation.width
                            new.size.width  -= value.translation.width
                            new.size.height += value.translation.height

                        case .bottomRight:
                            new.size.width  += value.translation.width
                            new.size.height += value.translation.height
                        }

                        if new.width < minSize { new.size.width = minSize }
                        if new.height < minSize { new.size.height = minSize }

                        new = clampRect(new, inside: imageFrame)
                        cropRect = new
                    }
                    .onEnded { _ in
                        activeCorner = nil
                    }
            )
    }

    private func clampRect(_ rect: CGRect, inside bounds: CGRect) -> CGRect {
        var r = rect

        let maxWidth  = bounds.width
        let maxHeight = bounds.height
        if r.width > maxWidth { r.size.width = maxWidth }
        if r.height > maxHeight { r.size.height = maxHeight }

        if r.minX < bounds.minX { r.origin.x = bounds.minX }
        if r.minY < bounds.minY { r.origin.y = bounds.minY }
        if r.maxX > bounds.maxX { r.origin.x = bounds.maxX - r.width }
        if r.maxY > bounds.maxY { r.origin.y = bounds.maxY - r.height }

        return r
    }

    private func overlayOutsideCrop() -> some View {
        Path { path in
            path.addRect(imageFrame)
            path.addRect(cropRect)
        }
        .fill(Color.black.opacity(0.45), style: FillStyle(eoFill: true))
    }

    // MARK: - OCR on crop (fixed)

    private func runOcrOnCrop() {
        let base = normalizedImage // ✅ crop from normalized image

        guard let cgImage = base.cgImage else {
            errorMessage = "تعذر قراءة الصورة."
            return
        }

        isProcessing = true
        errorMessage = nil

        let cgSize = CGSize(width: cgImage.width, height: cgImage.height)

        var rectInImage = convertCropRectToImageSpace(
            cgImageSize: cgSize,
            imageFrame: imageFrame,
            cropRect: cropRect
        ).integral

        // Clamp after rounding
        rectInImage.origin.x = max(0, min(rectInImage.origin.x, cgSize.width - 1))
        rectInImage.origin.y = max(0, min(rectInImage.origin.y, cgSize.height - 1))
        rectInImage.size.width = max(1, min(rectInImage.width, cgSize.width - rectInImage.origin.x))
        rectInImage.size.height = max(1, min(rectInImage.height, cgSize.height - rectInImage.origin.y))

        guard let croppedCG = cgImage.cropping(to: rectInImage) else {
            isProcessing = false
            errorMessage = "تعذر قص الصورة."
            return
        }

        // ✅ output is also normalized (.up)
        let croppedImage = UIImage(cgImage: croppedCG, scale: base.scale, orientation: .up)
        extractText(from: croppedImage)
    }

    private func extractText(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            isProcessing = false
            errorMessage = "تعذر قراءة الصورة."
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "حدث خطأ أثناء قراءة النص: \(error.localizedDescription)"
                }
                return
            }

            var lines: [String] = []

            if let results = request.results as? [VNRecognizedTextObservation] {
                for obs in results {
                    if let candidate = obs.topCandidates(1).first {
                        let s = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !s.isEmpty { lines.append(s) }
                    }
                }
            }

            let fullText = lines.joined(separator: "\n")

            DispatchQueue.main.async {
                self.isProcessing = false
                self.extractedTextPreview = fullText
                self.onTextExtracted(fullText)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        // If you ONLY want Arabic, keep only ar-SA.
        // If you want both, keep "en-US" too.
        request.recognitionLanguages = ["ar-SA", "en-US"]

        // ✅ We normalized => orientation is .up
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "حدث خطأ أثناء قراءة النص."
                }
            }
        }
    }

    // MARK: - Conversion from view space to image pixel space

    private func convertCropRectToImageSpace(
        cgImageSize: CGSize,
        imageFrame: CGRect,
        cropRect: CGRect
    ) -> CGRect {
        guard imageFrame.width > 0, imageFrame.height > 0 else { return .zero }

        let scaleX = cgImageSize.width / imageFrame.width
        let scaleY = cgImageSize.height / imageFrame.height

        let x = (cropRect.minX - imageFrame.minX) * scaleX
        let y = (cropRect.minY - imageFrame.minY) * scaleY
        let w = cropRect.width * scaleX
        let h = cropRect.height * scaleY

        let clampedX = max(0, min(x, cgImageSize.width - 1))
        let clampedY = max(0, min(y, cgImageSize.height - 1))
        let clampedW = max(1, min(w, cgImageSize.width - clampedX))
        let clampedH = max(1, min(h, cgImageSize.height - clampedY))

        return CGRect(x: clampedX, y: clampedY, width: clampedW, height: clampedH)
    }
}

// MARK: - UIImage normalization (orientation fix)
extension UIImage {
    func normalizedUp() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

#Preview {
    let testImage = UIImage(named: "Image") ?? UIImage()
    return CropView(image: testImage) { _ in }
}
