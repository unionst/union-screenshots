//
//  ScreenshotMode.swift
//  UnionScreenshots
//
//  Created by Union on 1/9/26.
//

import SwiftUI
import UIKit

// MARK: - UIKit Watermark View

/// A UIView that only appears in screenshots and screen recordings.
/// The content is hidden during normal use but becomes visible when captured.
///
/// Example:
/// ```swift
/// let watermark = UIScreenshotWatermarkView()
///
/// let label = UILabel()
/// label.text = "Wavelength"
/// watermark.contentView.addSubview(label)
///
/// view.addSubview(watermark)
/// ```
public class UIScreenshotWatermarkView: UIView {
    /// The container for content that should only appear in screenshots.
    /// Add your subviews to this view.
    public let contentView = UIView()

    private let secureField = UITextField()
    private var secureContainer: UIView?
    private var coverView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear

        // Content view holds the watermark content (at bottom layer)
        contentView.backgroundColor = .clear
        addSubview(contentView)

        // Secure text field on top - setting isSecureTextEntry creates a special container
        // that is hidden in screenshots
        secureField.isSecureTextEntry = true
        secureField.isUserInteractionEnabled = false
        secureField.backgroundColor = .clear
        addSubview(secureField)

        // Get the secure container that iOS creates inside the text field
        if let container = secureField.subviews.first {
            secureContainer = container

            // Add opaque cover inside secure container
            // This cover hides content normally, but disappears in screenshots
            let cover = UIView()
            cover.backgroundColor = .white // Will be updated in didMoveToWindow
            container.addSubview(cover)
            coverView = cover
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        secureField.frame = bounds
        secureContainer?.frame = bounds
        coverView?.frame = bounds
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        updateCoverColor()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateCoverColor()
        }
    }

    private func updateCoverColor() {
        // Walk up hierarchy to find background color
        var current: UIView? = superview
        while let view = current {
            if let bg = view.backgroundColor, bg != .clear {
                coverView?.backgroundColor = bg
                return
            }
            current = view.superview
        }
        // Fallback to system background
        coverView?.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
    }

    /// Manually set the cover color if auto-detection doesn't work for your use case.
    public func setCoverColor(_ color: UIColor) {
        coverView?.backgroundColor = color
    }
}

// MARK: - UIKit Secure View

/// A UIView that is hidden in screenshots and screen recordings.
/// The content is visible during normal use but disappears when captured.
///
/// Example:
/// ```swift
/// let secureView = UISecureView()
///
/// let secretLabel = UILabel()
/// secretLabel.text = "Secret Code: 1234"
/// secureView.contentView.addSubview(secretLabel)
///
/// view.addSubview(secureView)
/// ```
public class UISecureView: UIView {
    /// The container for content that should be hidden in screenshots.
    /// Add your subviews to this view.
    public let contentView = UIView()

    private let secureField = UITextField()
    private var secureContainer: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear

        // Secure text field - setting isSecureTextEntry creates a special container subview
        secureField.isSecureTextEntry = true
        secureField.isUserInteractionEnabled = false
        secureField.backgroundColor = .clear
        addSubview(secureField)

        // Get the secure container and add content inside it
        // Content inside the secure container will be hidden in screenshots
        if let container = secureField.subviews.first {
            secureContainer = container
            contentView.backgroundColor = .clear
            container.addSubview(contentView)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        secureField.frame = bounds
        secureContainer?.frame = bounds
        contentView.frame = bounds
    }
}

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

    /// Replaces this view with different content during screen capture.
    ///
    /// The original view is shown during normal use, but when a screenshot
    /// or screen recording is taken, the replacement content appears instead.
    ///
    /// ```swift
    /// Text("Secret: 1234")
    ///     .screenshotReplacement {
    ///         Text("Nice try!")
    ///     }
    /// ```
    ///
    /// - Parameter replacement: A view builder that creates the replacement content.
    /// - Returns: A view that swaps content during screen capture.
    func screenshotReplacement<Replacement: View>(
        @ViewBuilder _ replacement: @escaping () -> Replacement
    ) -> some View {
        modifier(ScreenshotReplacementModifier(replacement: replacement))
    }

    /// Conditionally replaces this view with different content during screen capture.
    ///
    /// - Parameters:
    ///   - enabled: Whether the replacement should be active.
    ///   - replacement: A view builder that creates the replacement content.
    /// - Returns: A view that swaps content during screen capture when enabled.
    @ViewBuilder
    func screenshotReplacement<Replacement: View>(
        enabled: Bool,
        @ViewBuilder _ replacement: @escaping () -> Replacement
    ) -> some View {
        if enabled {
            modifier(ScreenshotReplacementModifier(replacement: replacement))
        } else {
            self
        }
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

// MARK: - Screenshot Replacement Modifier

private struct ScreenshotReplacementModifier<Replacement: View>: ViewModifier {
    let replacement: () -> Replacement

    func body(content: Content) -> some View {
        ScreenshotReplacementView(replacement: replacement) { content }
    }
}

// MARK: - Screenshot Replacement View

private struct ScreenshotReplacementView<Original: View, Replacement: View>: View {
    let original: Original
    let replacement: () -> Replacement
    @Environment(\.colorScheme) private var colorScheme

    init(replacement: @escaping () -> Replacement, @ViewBuilder original: () -> Original) {
        self.original = original()
        self.replacement = replacement
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        ZStack {
            replacement()

            SecureContainer {
                backgroundColor
                    .overlay {
                        original
                    }
            }
            .id(colorScheme)
        }
        .clipped()
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
    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        // Hidden content for sizing - keeps watermark text invisible during sampling
        content
            .hidden()
            .background(
                BackgroundColorSampler { color in
                    sampledColor = color
                }
                .id(colorScheme) // Force recreation on color scheme change
            )
            .overlay {
                // Only show content after sampling completes
                if let sampledColor {
                    ZStack {
                        content

                        SecureContainer {
                            Rectangle()
                                .fill(sampledColor)
                                .ignoresSafeArea()
                        }
                    }
                }
            }
            .onChange(of: colorScheme) {
                sampledColor = nil // Reset to trigger re-sample
            }
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

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }

            Task { @MainActor in
                // Delay to ensure the view hierarchy is fully rendered
                try? await Task.sleep(for: .milliseconds(100))
                if let color = self.sampleBackgroundColor() {
                    self.onColor?(Color(uiColor: color))
                }
            }
        }

        @MainActor
        private func sampleBackgroundColor() -> UIColor? {
            guard let window = self.window else { return nil }

            // Ensure we have valid bounds before sampling
            guard bounds.width > 0, bounds.height > 0 else { return nil }

            // Hide just ourselves during sampling
            let wasHidden = self.isHidden
            self.isHidden = true
            defer { self.isHidden = wasHidden }

            // Sample a single pixel at the center of our bounds
            let centerInWindow = self.convert(
                CGPoint(x: bounds.midX, y: bounds.midY),
                to: window
            )

            // Validate the point is within the window
            guard window.bounds.contains(centerInWindow) else { return nil }

            return pixelColor(in: window, at: centerInWindow)
        }

        @MainActor
        private func pixelColor(in window: UIWindow, at point: CGPoint) -> UIColor? {
            // Create a 1x1 bitmap context with a known RGBA format
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            var pixel: [UInt8] = [0, 0, 0, 0]

            guard let context = CGContext(
                data: &pixel,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return nil
            }

            // Translate so the target point renders at (0,0)
            context.translateBy(x: -point.x, y: -point.y)
            window.layer.render(in: context)

            // Now we have known RGBA format
            let r = CGFloat(pixel[0]) / 255.0
            let g = CGFloat(pixel[1]) / 255.0
            let b = CGFloat(pixel[2]) / 255.0
            let a = CGFloat(pixel[3]) / 255.0

            // If the sampled pixel is mostly transparent, use the window's
            // actual background color rather than the semantic systemBackground
            if a < 0.5 {
                if let windowBgColor = window.backgroundColor, windowBgColor != .clear {
                    return windowBgColor
                }
                if let rootBgColor = window.rootViewController?.view.backgroundColor, rootBgColor != .clear {
                    return rootBgColor
                }
                // Last resort fallback
                return UIColor.systemBackground
            }

            return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        }
    }
}
