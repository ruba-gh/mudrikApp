//
//  CameraView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 10/06/1447 AH.
//

import SwiftUI
import PhotosUI   // Used for selecting images from the photo library

struct CameraView: View {
    let category: String?

    init(category: String? = nil) {
        self.category = category
    }

    @State private var selectedImage: UIImage? = nil
    @State private var showPhotoPicker = false
    @State private var showCropView = false

    @State private var extractedText: String = ""   // Holds the OCR result from the cropped image

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // Display the selected image (optional)
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                AppButton(
                    title: "من الصور",
                    iconName: "photo.on.rectangle",
                    type: .orange
                ) {
                    showPhotoPicker = true
                }

                AppButton(
                    title: "من الملفات",
                    iconName: "folder",
                    type: .systemBlack
                ) {
                    // TODO: Implement a Document Picker if needed
                    print("Files tapped")
                }

                // Display extracted text if available
                if !extractedText.isEmpty {
                    Text("النص المستخرج:")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ScrollView {
                        Text(extractedText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("الكاميرا / اختيار الصورة")

            // Navigate to CropView after an image is selected
            .navigationDestination(isPresented: $showCropView) {
                if let selectedImage {
                    CropView(image: selectedImage) { text in
                        // Called when the crop screen finishes extracting text
                        extractedText = text
                        print("TEXT:", text)   // Print OCR result in console
                    }
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(image: $selectedImage)
        }
        // Automatically open CropView once an image is picked
        .onChange(of: selectedImage) { newValue in
            if newValue != nil {
                showCropView = true
            }
        }
    }
}

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
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    // Normalize image orientation before returning it
                    self.parent.image = (image as? UIImage)?.normalizedUp()
                }
            }
        }
    }
}

// Ensures the UIImage is always in `.up` orientation by redrawing it
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
    CameraView()
}
