import SwiftUI
import UIKit

struct AlertAction {
    enum Style {
        case `default`
        case cancel
        case destructive

        var uiStyle: UIAlertAction.Style {
            switch self {
            case .default: return .default
            case .cancel: return .cancel
            case .destructive: return .destructive
            }
        }
    }

    let title: String
    let style: Style
    let handler: (() -> Void)?

    init(_ title: String, style: Style = .default, handler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

struct AlertTextFieldConfig {
    let placeholder: String?
    let text: Binding<String>
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?

    init(placeholder: String? = nil,
         text: Binding<String>,
         isSecure: Bool = false,
         keyboardType: UIKeyboardType = .default,
         textContentType: UITextContentType? = nil) {
        self.placeholder = placeholder
        self.text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textContentType = textContentType
    }
}

struct AlertConfig: Identifiable {
    enum PreferredStyle {
        case alert
        case actionSheet

        var uiStyle: UIAlertController.Style {
            switch self {
            case .alert: return .alert
            case .actionSheet: return .actionSheet
            }
        }
    }

    let id = UUID()
    let title: String?
    let message: String?
    let preferredStyle: PreferredStyle
    var textFields: [AlertTextFieldConfig] = []
    var actions: [AlertAction] = []
}

private struct AlertPresenterController: UIViewControllerRepresentable {
    @Binding var config: AlertConfig?

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.isHidden = true
        vc.view.backgroundColor = .clear
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let config = config, uiViewController.presentedViewController == nil else { return }

        let alert = UIAlertController(title: config.title, message: config.message, preferredStyle: config.preferredStyle.uiStyle)

        // Text fields (alert style only)
        if config.preferredStyle == .alert {
            for tf in config.textFields {
                alert.addTextField { textField in
                    textField.placeholder = tf.placeholder
                    textField.isSecureTextEntry = tf.isSecure
                    textField.keyboardType = tf.keyboardType
                    textField.textContentType = tf.textContentType
                    textField.text = tf.text.wrappedValue

                    // Keep binding updated as user types
                    textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
                    context.coordinator.bindings[textField] = tf.text
                }
            }
        }

        for action in config.actions {
            let uiAction = UIAlertAction(title: action.title, style: action.style.uiStyle) { _ in
                action.handler?()
            }
            alert.addAction(uiAction)
        }

        // iPad action sheet anchor
        if let pop = alert.popoverPresentationController, let view = uiViewController.view {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 1, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }

        uiViewController.present(alert, animated: true) {
            // Clear the config so subsequent updates can present again
            DispatchQueue.main.async {
                self.config = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var bindings: [UITextField: Binding<String>] = [:]

        @objc func textDidChange(_ sender: UITextField) {
            guard let binding = bindings[sender] else { return }
            binding.wrappedValue = sender.text ?? ""
        }
    }
}

private struct AlertPresenterModifier: ViewModifier {
    @Binding var alertConfig: AlertConfig?

    func body(content: Content) -> some View {
        content
            .background(AlertPresenterController(config: $alertConfig))
    }
}

extension View {
    func systemAlert(config: Binding<AlertConfig?>) -> some View {
        self.modifier(AlertPresenterModifier(alertConfig: config))
    }
}
