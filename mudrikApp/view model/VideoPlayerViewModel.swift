import Foundation
import SwiftUI
import Combine
import AVKit

@MainActor
final class VideoPlayerViewModel: ObservableObject {

    // Inputs
    let extractedText: String?
    let clipNameFromLibrary: String?
    let clipID: UUID?                 // ✅ الجديد (للتعديل والحذف الصحيح)

    // Bindings passed through from parent
    @Binding var allSavedClips: [SavedClip]
    @Binding var categories: [String]
    @Binding var navigateToLibrary: Bool

    // Local UI state (حفظ - كما هو)
    @Published var showSavePopup = false
    @Published var showCategoryPopup = false
    @Published var popupKind: PopupKind = .clipName
    @Published var inputText: String = ""
    @Published var clipName: String = ""
    @Published var selectedCategory: String? = nil

    // Local UI state (تعديل الاسم للمحفوظ)
    @Published var isEditingTitle: Bool = false
    @Published var editedTitle: String = ""

    // Local UI state (تأكيد الحذف)
    @Published var showDeleteConfirm: Bool = false

    init(
        extractedText: String? = nil,
        clipNameFromLibrary: String? = nil,
        clipID: UUID? = nil,
        allSavedClips: Binding<[SavedClip]>,
        categories: Binding<[String]>,
        navigateToLibrary: Binding<Bool>
    ) {
        self.extractedText = extractedText
        self.clipNameFromLibrary = clipNameFromLibrary
        self.clipID = clipID

        self._allSavedClips = allSavedClips
        self._categories = categories
        self._navigateToLibrary = navigateToLibrary

        // لو فتحنا مقطع محفوظ: جهّز الاسم الحالي للتعديل
        if let id = clipID,
           let clip = allSavedClips.wrappedValue.first(where: { $0.id == id }) {
            self.clipName = clip.name
            self.editedTitle = clip.name
        }
    }

    var isFromLibrary: Bool { clipID != nil }
    var isFromOCR: Bool { clipID == nil }

    var pageTitle: String {
        if isFromLibrary {
            return clipName
        } else if let text = extractedText, !text.isEmpty {
            return "ترجمة النص"
        } else {
            return "صفحة الفيديو"
        }
    }

    var categoriesForPopup: [String] {
        var list = categories
        if !list.contains("المكتبة") {
            list.insert("المكتبة", at: 0)
        }
        return list
    }

    // =========================
    // ✅ الحفظ — نفس منطقك تمامًا
    // =========================
    func onTapSaveButton() {
        popupKind = .clipName
        inputText = ""
        showSavePopup = true
    }

    func handleTextFieldConfirm() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch popupKind {
        case .clipName:
            // 1) حفظ اسم المقطع ثم فتح اختيار التصنيف
            clipName = trimmed
            showSavePopup = false
            showCategoryPopup = true

        case .categoryName:
            // 3) إضافة تصنيف جديد ثم حفظ المقطع
            if !categories.contains(trimmed) {
                categories.append(trimmed)
            }
            showSavePopup = false
            saveClipAndNavigate(category: trimmed)
        }
    }

    func addNewCategoryFlow() {
        // 2-ب) المستخدم اختار إضافة تصنيف جديد → افتح نافذة اسم التصنيف
        popupKind = .categoryName
        inputText = ""
        showCategoryPopup = false
        showSavePopup = true
    }

    func selectCategoryAndSave(_ category: String) {
        // 2-أ) المستخدم اختار تصنيف موجود → احفظ
        selectedCategory = category
        showCategoryPopup = false
        saveClipAndNavigate(category: category)
    }

    private func saveClipAndNavigate(category: String) {
        if !categories.contains(category) {
            categories.append(category)
        }

        let finalClipName = clipName.isEmpty ? "مقطع بدون اسم" : clipName

        // Generate a unique file name for the video to avoid overwriting
        let uniqueFileName = UUID().uuidString + ".mp4"

        let newClip = SavedClip(
            name: finalClipName,
            category: category,
            videoFileName: uniqueFileName
        )

        allSavedClips.append(newClip)

        StorageManager().saveClips(allSavedClips)
        StorageManager().saveCategories(categories)

        navigateToLibrary = true
    }

    // =========================
    // ✅ تعديل الاسم — للمحفوظ فقط
    // =========================
    func startEditingTitle() {
        guard isFromLibrary else { return }
        editedTitle = clipName
        isEditingTitle = true
    }

    func saveEditedTitle() {
        guard isFromLibrary, let id = clipID else { return }

        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let index = allSavedClips.firstIndex(where: { $0.id == id }) {
            allSavedClips[index].name = trimmed
            StorageManager().saveClips(allSavedClips)

            // تحديث العنوان في نفس الصفحة
            clipName = trimmed
            isEditingTitle = false
        }
    }

    // =========================
    // ✅ حذف — للمحفوظ فقط + يرجع للمكتبة
    // =========================
    func confirmDelete() {
        guard isFromLibrary else { return }
        showDeleteConfirm = true
    }

    func deleteClip() {
        guard isFromLibrary, let id = clipID else { return }

        allSavedClips.removeAll { $0.id == id }
        StorageManager().saveClips(allSavedClips)

        navigateToLibrary = true
    }
}
