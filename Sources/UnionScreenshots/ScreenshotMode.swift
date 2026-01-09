//
//  ScreenshotMode.swift
//  UnionScreenshots
//
//  Created by Union on 1/9/26.
//

import SwiftUI

// MARK: - Screenshot Mode

/// Defines how a view behaves during screen capture.
public enum ScreenshotMode {
    /// The view behaves normally, visible in both regular viewing and screenshots.
    case visible

    /// The view is hidden during screenshots and screen recordings.
    case secure

    /// The view is only visible during screenshots and screen recordings.
    case _watermark(background: AnyShapeStyle)

    /// Watermark using the system background style.
    public static var watermark: ScreenshotMode {
        ._watermark(background: AnyShapeStyle(.background))
    }

    /// Watermark with a custom background style.
    public static func watermark<S: ShapeStyle>(background: S) -> ScreenshotMode {
        ._watermark(background: AnyShapeStyle(background))
    }
}

// MARK: - View Extension

public extension View {
    /// Controls how this view appears during screen capture.
    ///
    /// Use `.visible` for normal behavior (useful for conditional logic):
    /// ```swift
    /// Text("Hello")
    ///     .screenshotMode(isProtected ? .secure : .visible)
    /// ```
    ///
    /// Use `.secure` to hide sensitive content from screenshots and recordings:
    /// ```swift
    /// Text("Secret Code: 1234")
    ///     .screenshotMode(.secure)
    /// ```
    ///
    /// Use `.watermark` to show content only in screenshots (hidden during normal use):
    /// ```swift
    /// Text("CONFIDENTIAL")
    ///     .screenshotMode(.watermark)  // uses system background
    ///
    /// Text("CONFIDENTIAL")
    ///     .screenshotMode(.watermark(background: .white))  // custom color
    ///
    /// Text("CONFIDENTIAL")
    ///     .screenshotMode(.watermark(background: .regularMaterial))  // material
    /// ```
    ///
    /// - Parameter mode: The screenshot behavior mode.
    /// - Returns: A view with the specified screenshot behavior.
    func screenshotMode(_ mode: ScreenshotMode) -> some View {
        modifier(ScreenshotModeModifier(mode: mode))
    }
}

// MARK: - Modifier

private struct ScreenshotModeModifier: ViewModifier {
    let mode: ScreenshotMode

    func body(content: Content) -> some View {
        switch mode {
        case .visible:
            content
        case .secure:
            SecureContentView { content }
        case ._watermark(let background):
            WatermarkContentView(background: background) { content }
        }
    }
}

// MARK: - Secure Content View (hidden in capture)

private struct SecureContentView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .hidden()
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScreenshotModeSizeKey.self, value: geometry.size)
                }
            )
            .overlayPreferenceValue(ScreenshotModeSizeKey.self) { _ in
                SecureContainerView(content: content)
            }
    }
}

// MARK: - Watermark Content View (visible only in capture)

private struct WatermarkContentView<Content: View>: View {
    let background: AnyShapeStyle
    let content: Content

    init(background: AnyShapeStyle, @ViewBuilder content: () -> Content) {
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .hidden()
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScreenshotModeSizeKey.self, value: geometry.size)
                }
            )
            .overlayPreferenceValue(ScreenshotModeSizeKey.self) { _ in
                ZStack {
                    // Content underneath - visible in screenshots
                    content

                    // Secure opaque layer on top - hides content normally, disappears in screenshots
                    SecureContainerView(
                        content: Rectangle().fill(background)
                    )
                }
            }
    }
}

// MARK: - Size Preference Key

private struct ScreenshotModeSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Secure Container (UIViewRepresentable)

private struct SecureContainerView<Content: View>: UIViewRepresentable {
    let content: Content

    func makeUIView(context: Context) -> UIView {
        let secureField = UITextField()
        secureField.isSecureTextEntry = true

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
        if let hostingView = uiView.subviews.first,
           let hostingController = hostingView.next as? UIHostingController<Content> {
            hostingController.rootView = content
        }
    }
}
