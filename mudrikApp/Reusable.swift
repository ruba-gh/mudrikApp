//
//  Reusable.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 09/06/1447 AH.
//



import SwiftUI

struct AppButton: View {
    
    enum StyleType {
        case systemWhite
        case systemBlack
        case orange
    }
    
    let title: String
    let iconName: String?         
    let type: StyleType
    let action: () -> Void

    init(
        title: String,
        iconName: String? = nil,
        type: StyleType,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.type = type
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .imageScale(.medium)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .cornerRadius(100)
            .glassEffect()
            .glassEffect(.regular.interactive())
        }
    }
    
    private var backgroundColor: Color {
        switch type {
        case .systemWhite:
            return Color(.systemBackground)
        case .systemBlack:
            return Color(.label)
        case .orange:
            return Color.orange
        }
    }
    
    private var textColor: Color {
        switch type {
        case .systemWhite:
            return Color(.label)
        case .systemBlack:
            return Color(.systemBackground)
        case .orange:
            return .black
        }
    }
}


struct RoundOrangeButton: View {
    let size: CGFloat
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: size, height: size)
                .background(Color.orange)
                .clipShape(Circle())
                .glassEffect()
                .glassEffect(.regular.interactive())
        }
    }
}

enum PopupKind {
    case clipName
    case categoryName
    
    var title: String {
        switch self {
        case .clipName:      return "اسم المقطع"
        case .categoryName:  return "اسم التصنيف"
        }
    }
    
    var placeholder: String {
        switch self {
        case .clipName:      return "اكتب اسم المقطع"
        case .categoryName:  return "اكتب اسم التصنيف"
        }
    }
    
   
    var leftIcon: String {
        switch self {
        case .clipName:      return "xmark"
        case .categoryName:  return "chevron.backward"
        }
    }
}

struct TextFieldAlert: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let kind: PopupKind
    @Binding var text: String
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        let bgColor      = colorScheme == .light ? Color.black : Color.white
        let textColor    = colorScheme == .light ? Color.white : Color.black
        let fieldBgColor = Color.gray.opacity(0.3)
        
        VStack(spacing: 8) {
            
            Text(kind.title)
                .font(.headline)
                .foregroundColor(textColor)
            
            
            TextField(kind.placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(fieldBgColor)
                .cornerRadius(4)
                .foregroundColor(textColor)
            
            Divider()
                .overlay(Color.gray.opacity(0.5))
            
            HStack(spacing: 0) {
                Button(action: onCancel) {
                    Image(systemName: kind.leftIcon)
                        .font(.system(size: 18, weight: .medium))
                }
                .frame(maxWidth: .infinity, maxHeight: 36)
                .foregroundColor(textColor)
                
                Divider()
                    .overlay(Color.gray.opacity(0.5))
                
                Button(action: onConfirm) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .medium))
                }
                .frame(maxWidth: .infinity, maxHeight: 36)
                .foregroundColor(.orange)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .fixedSize(horizontal: false, vertical: true)
        .background(bgColor)
        .cornerRadius(18)
        .shadow(radius: 8)
        .frame(maxWidth: 320)
        .padding(.horizontal, 32)
    }
}
