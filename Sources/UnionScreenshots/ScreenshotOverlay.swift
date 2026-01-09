//
//  ScreenshotOverlay.swift
//  UnionScreenshots
//
//  Created by Union on 1/8/26.
//

import SwiftUI

// MARK: - Display Type

/// The type of top display area on the current device
public enum DisplayType: Sendable {
    /// Dynamic Island (iPhone 14 Pro and later)
    case dynamicIsland
    /// Notch (iPhone X through iPhone 14)
    case notch
    /// No cutout (older devices, SE, etc.)
    case none
}

// MARK: - Device Detection

/// Detects the type of display cutout on the current device
@MainActor
public func detectDisplayType() -> DisplayType {
    guard let windowScene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first
    else { return .none }

    let safeAreaTop = windowScene.windows.first?.safeAreaInsets.top ?? 0

    if safeAreaTop >= 59 {
        return .dynamicIsland
    } else if safeAreaTop >= 44 {
        return .notch
    } else {
        return .none
    }
}

// MARK: - Pass Through Window

private class PassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
              let rootView = rootViewController?.view else {
            return nil
        }

        // Pass through touches that hit the root view directly
        if hitView === rootView {
            return nil
        }

        return hitView
    }
}

// MARK: - Window Extractor

private struct WindowExtractor: UIViewRepresentable {
    var onWindowFound: (UIWindow) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            if let window = view.window {
                onWindowFound(window)
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Screenshot Overlay Content View

private struct ScreenshotOverlayContentView<OverlayContent: View>: View {
    let displayType: DisplayType
    let alignment: HorizontalAlignment
    let content: () -> OverlayContent

    // Dynamic Island dimensions
    private let dynamicIslandWidth: CGFloat = 120
    private let dynamicIslandHeight: CGFloat = 36

    // Notch dimensions
    private let notchWidth: CGFloat = 210
    private let notchHeight: CGFloat = 30

    var body: some View {
        GeometryReader { proxy in
            let safeAreaTop = proxy.safeAreaInsets.top
            let frame = frame(for: displayType, safeAreaTop: safeAreaTop, screenWidth: proxy.size.width)

            if alignment == .center {
                content()
                    .frame(width: frame.width, height: frame.height)
                    .frame(maxWidth: .infinity)
                    .offset(y: frame.minY)
            } else {
                content()
                    .frame(height: frame.height)
                    .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
                    .offset(y: frame.minY)
            }
        }
        .ignoresSafeArea()
    }

    private func frame(for displayType: DisplayType, safeAreaTop: CGFloat, screenWidth: CGFloat) -> CGRect {
        switch displayType {
        case .dynamicIsland:
            let topOffset = 11 + max((safeAreaTop - 59), 0)
            let x = (screenWidth - dynamicIslandWidth) / 2
            return CGRect(x: x, y: topOffset, width: dynamicIslandWidth, height: dynamicIslandHeight)
        case .notch:
            let x = (screenWidth - notchWidth) / 2
            return CGRect(x: x, y: 0, width: notchWidth, height: notchHeight)
        case .none:
            return .zero
        }
    }
}

// MARK: - Screenshot Overlay Modifier

private struct ScreenshotOverlayModifier<OverlayContent: View>: ViewModifier {
    let alignment: HorizontalAlignment
    let overlayContent: () -> OverlayContent

    @State private var overlayWindow: PassThroughWindow?
    @State private var displayType: DisplayType? = nil

    func body(content: Content) -> some View {
        content
            .background(WindowExtractor { mainWindow in
                setupOverlayWindow(mainWindow)
            })
            .onAppear {
                displayType = detectDisplayType()
            }
            .onChange(of: displayType) { _, newValue in
                updateOverlayContent()
            }
    }

    private func setupOverlayWindow(_ mainWindow: UIWindow) {
        guard overlayWindow == nil,
              let windowScene = mainWindow.windowScene else { return }

        let window = PassThroughWindow(windowScene: windowScene)
        window.windowLevel = .alert + 10
        window.backgroundColor = .clear
        window.isHidden = false
        window.isUserInteractionEnabled = true

        self.overlayWindow = window
        updateOverlayContent()
    }

    private func updateOverlayContent() {
        guard let window = overlayWindow,
              let displayType = displayType,
              displayType != .none else {
            overlayWindow?.isHidden = true
            return
        }

        let hostingView = ScreenshotOverlayContentView(
            displayType: displayType,
            alignment: alignment,
            content: overlayContent
        )

        let hosting = UIHostingController(rootView: hostingView)
        hosting.view.backgroundColor = .clear

        window.rootViewController = hosting
        window.isHidden = false
    }
}

// MARK: - View Extension

public extension View {
    /// Positions content underneath the device's Dynamic Island or notch using a window overlay.
    ///
    /// On devices with a Dynamic Island, the content appears just below the island.
    /// On devices with a notch, the content appears just below the notch.
    /// On devices without either, the content is not displayed.
    ///
    /// - Parameters:
    ///   - alignment: The horizontal alignment of the content (default: .center)
    ///   - content: A view builder that creates the content to display
    /// - Returns: A view with the screenshot overlay applied
    ///
    /// Example:
    /// ```swift
    /// ContentView()
    ///     .screenshotOverlay {
    ///         Text("Recording")
    ///             .font(.caption)
    ///             .foregroundStyle(.red)
    ///     }
    /// ```
    func screenshotOverlay<Content: View>(
        alignment: HorizontalAlignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ScreenshotOverlayModifier(alignment: alignment, overlayContent: content))
    }
}
