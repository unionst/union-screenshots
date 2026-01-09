//
//  ScreenshotPreventView.swift
//  UnionScreenshots
//
//  Created by Union on 1/9/26.
//

import SwiftUI

// MARK: - Screenshot Prevent View

/// A container view that hides its content from screenshots, screen recordings,
/// and other screen capture methods.
///
/// This view leverages the same underlying mechanism that iOS uses for `SecureField`
/// to prevent sensitive content from appearing in screen captures. The content will
/// be visible during normal use but will appear blank in:
/// - Screenshots
/// - Screen recordings
/// - QuickTime mirroring
/// - AirPlay mirroring
///
/// Example:
/// ```swift
/// ScreenshotPreventView {
///     Text("Sensitive Information")
///         .font(.title)
/// }
/// ```
///
/// - Note: This technique works on iOS 15 and later.
public struct ScreenshotPreventView<Content: View>: View {

    private var content: Content

    /// Creates a screenshot-protected container view.
    /// - Parameter content: The content to protect from screen capture.
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    @State private var contentSize: CGSize = .zero

    public var body: some View {
        content
            .hidden()
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScreenshotPreventSizeKey.self, value: geometry.size)
                }
            )
            .onPreferenceChange(ScreenshotPreventSizeKey.self) { size in
                contentSize = size
            }
            .overlay(
                _ScreenshotPreventHelper(content: content, size: contentSize)
            )
    }
}

// MARK: - Size Preference Key

private struct ScreenshotPreventSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - UIViewRepresentable Helper

private struct _ScreenshotPreventHelper<Content: View>: UIViewRepresentable {
    let content: Content
    let size: CGSize

    func makeUIView(context: Context) -> UIView {
        let secureField = UITextField()
        secureField.isSecureTextEntry = true

        // The secure text field has a special internal subview that iOS uses
        // to hide content from screen captures. We extract and use that view.
        guard let secureContainer = secureField.subviews.first else {
            return UIView()
        }

        secureContainer.translatesAutoresizingMaskIntoConstraints = false

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        secureContainer.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: secureContainer.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: secureContainer.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: secureContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: secureContainer.trailingAnchor),
        ])

        return secureContainer
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the hosting controller's root view if content changes
        if let hostingView = uiView.subviews.first,
           let hostingController = hostingView.next as? UIHostingController<Content> {
            hostingController.rootView = content
        }
    }
}

// MARK: - View Modifier

/// A view modifier that protects content from screenshots and screen recordings.
private struct ScreenshotPreventModifier: ViewModifier {
    func body(content: Content) -> some View {
        ScreenshotPreventView {
            content
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Protects this view from appearing in screenshots and screen recordings.
    ///
    /// When this modifier is applied, the view will be visible during normal use
    /// but will appear blank in screen captures, recordings, and mirroring.
    ///
    /// Example:
    /// ```swift
    /// Text("Secret Code: 1234")
    ///     .screenshotProtected()
    /// ```
    ///
    /// - Returns: A view that is protected from screen capture.
    func screenshotProtected() -> some View {
        modifier(ScreenshotPreventModifier())
    }
}
