//
//  ScreenshotMode.swift
//  UnionScreenshots
//
//  Created by Union on 1/9/26.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Screenshot Mode

/// Defines how a view behaves during screen capture.
public enum ScreenshotMode: Sendable {
    /// The view behaves normally, visible in both regular viewing and screenshots.
    case visible

    /// The view is hidden during screenshots and screen recordings.
    case secure

    /// The view is only visible during screenshots and screen recordings.
    /// Automatically samples the background color behind the view.
    case watermark

    /// The view is only visible during screenshots and screen recordings.
    /// Uses a custom background style to hide the content during normal viewing.
    case _watermarkWithBackground(AnyShapeStyle)

    /// Watermark with a custom background style.
    public static func watermark<S: ShapeStyle>(background: S) -> ScreenshotMode {
        ._watermarkWithBackground(AnyShapeStyle(background))
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
    ///     .screenshotMode(.watermark)  // auto-detects background
    ///
    /// Text("CONFIDENTIAL")
    ///     .screenshotMode(.watermark(background: .white))  // explicit background
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
        case .watermark:
            AutoWatermarkContentView { content }
        case ._watermarkWithBackground(let background):
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
                SecureContainer {
                    content
                }
            )
    }
}

// MARK: - Auto Watermark Content View (auto-samples background)

private struct AutoWatermarkContentView<Content: View>: View {
    let content: Content
    @State private var sampledColor: Color?

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Content underneath - visible in screenshots
            content

            // Secure opaque layer on top - hides content normally, disappears in screenshots
            if let sampledColor {
                SecureContainer {
                    Rectangle()
                        .fill(sampledColor)
                        .ignoresSafeArea()
                }
            }
        }
        .background(
            BackgroundColorSampler { color in
                sampledColor = color
            }
        )
    }
}

// MARK: - Watermark Content View (explicit background)

private struct WatermarkContentView<Content: View>: View {
    let background: AnyShapeStyle
    let content: Content

    init(background: AnyShapeStyle, @ViewBuilder content: () -> Content) {
        self.background = background
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Content underneath - visible in screenshots
            content

            // Secure opaque layer on top - hides content normally, disappears in screenshots
            SecureContainer {
                Rectangle()
                    .fill(background)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Secure Container

private struct SecureContainer<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    @State private var hostingController: UIHostingController<Content>?

    var body: some View {
        _SecureContainerHelper(hostingController: $hostingController)
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SecureContainerSizeKey.self, value: geometry.size)
                        .onPreferenceChange(SecureContainerSizeKey.self) { size in
                            if size != .zero {
                                if hostingController == nil {
                                    hostingController = UIHostingController(rootView: content)
                                    hostingController?.view.backgroundColor = .clear
                                    hostingController?.view.tag = 1009
                                    hostingController?.view.frame = CGRect(origin: .zero, size: size)
                                } else {
                                    hostingController?.view.frame = CGRect(origin: .zero, size: size)
                                }
                            }
                        }
                }
            )
    }
}

// MARK: - Size Preference Key

private struct SecureContainerSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Secure Container Helper (UIViewRepresentable)

private struct _SecureContainerHelper<Content: View>: UIViewRepresentable {
    @Binding var hostingController: UIHostingController<Content>?

    func makeUIView(context: Context) -> UIView {
        let secureField = UITextField()
        secureField.isSecureTextEntry = true

        if let textLayoutView = secureField.subviews.first {
            return textLayoutView
        }

        return UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let hostingController, !uiView.subviews.contains(where: { $0.tag == 1009 }) {
            uiView.addSubview(hostingController.view)
        }
    }
}

// MARK: - Background Color Sampler

private struct BackgroundColorSampler: UIViewRepresentable {
    var onColor: @MainActor (Color) -> Void

    func makeUIView(context: Context) -> SamplerView {
        let view = SamplerView()
        view.onColor = onColor
        return view
    }

    func updateUIView(_ uiView: SamplerView, context: Context) {
        uiView.onColor = onColor
    }

    final class SamplerView: UIView {
        var onColor: (@MainActor (Color) -> Void)?
        private var didSample = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard !didSample, window != nil else { return }
            didSample = true

            Task { @MainActor in
                // Small delay to ensure the view hierarchy is fully rendered
                try? await Task.sleep(for: .milliseconds(50))
                if let color = self.sampleBackgroundColor() {
                    self.onColor?(Color(uiColor: color))
                }
            }
        }

        @MainActor
        private func sampleBackgroundColor() -> UIColor? {
            guard let window = self.window else { return nil }

            let inset: CGFloat = 2
            let rectInWindow = self
                .convert(self.bounds.insetBy(dx: inset, dy: inset), to: window)
                .integral
                .intersection(window.bounds)

            guard rectInWindow.width > 1, rectInWindow.height > 1 else { return nil }

            let wasHidden = self.isHidden
            self.isHidden = true
            defer { self.isHidden = wasHidden }

            guard let cgImage = snapshot(window: window, rect: rectInWindow) else { return nil }
            return averageColor(from: cgImage)
        }

        @MainActor
        private func snapshot(window: UIWindow, rect: CGRect) -> CGImage? {
            let format = UIGraphicsImageRendererFormat()
            format.scale = window.screen.scale
            format.opaque = false

            let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
            let image = renderer.image { ctx in
                ctx.cgContext.translateBy(x: -rect.minX, y: -rect.minY)
                window.layer.render(in: ctx.cgContext)
            }

            return image.cgImage
        }

        private func averageColor(from cgImage: CGImage) -> UIColor? {
            let ciContext = CIContext(options: [
                .workingColorSpace: NSNull(),
                .outputColorSpace: NSNull()
            ])

            let input = CIImage(cgImage: cgImage)

            let filter = CIFilter.areaAverage()
            filter.inputImage = input
            filter.extent = input.extent

            guard let output = filter.outputImage else { return nil }

            var rgba = [UInt8](repeating: 0, count: 4)
            ciContext.render(
                output,
                toBitmap: &rgba,
                rowBytes: 4,
                bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: CGColorSpaceCreateDeviceRGB()
            )

            return UIColor(
                red: CGFloat(rgba[0]) / 255,
                green: CGFloat(rgba[1]) / 255,
                blue: CGFloat(rgba[2]) / 255,
                alpha: CGFloat(rgba[3]) / 255
            )
        }
    }
}
