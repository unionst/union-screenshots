//
//  ScreenshotCutout.swift
//  UnionScreenshots
//
//  Created by Union on 1/8/26.
//

import SwiftUI

// MARK: - Device Cutout Type

/// The type of display cutout on the current device
public enum DeviceCutout: Sendable {
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
public func detectDeviceCutout() -> DeviceCutout {
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

// MARK: - Cutout Dimensions

/// Returns the dimensions and position of the device cutout
@MainActor
public func cutoutFrame(in windowScene: UIWindowScene) -> CGRect? {
    guard let window = windowScene.windows.first else { return nil }

    let safeAreaTop = window.safeAreaInsets.top
    let screenWidth = window.bounds.width

    if safeAreaTop >= 59 {
        // Dynamic Island: centered pill shape
        let width: CGFloat = 126
        let height: CGFloat = 37
        let x = (screenWidth - width) / 2
        let y: CGFloat = 11
        return CGRect(x: x, y: y, width: width, height: height)
    } else if safeAreaTop >= 44 {
        // Notch: wider centered area
        let width: CGFloat = 210
        let height: CGFloat = 30
        let x = (screenWidth - width) / 2
        let y: CGFloat = 0
        return CGRect(x: x, y: y, width: width, height: height)
    } else {
        return nil
    }
}

// MARK: - Screenshot Cutout Modifier

private struct ScreenshotCutoutModifier<CutoutContent: View>: ViewModifier {
    let alignment: HorizontalAlignment
    let cutoutContent: () -> CutoutContent

    @State private var deviceCutout: DeviceCutout? = nil

    func body(content: Content) -> some View {
        if let cutout = deviceCutout {
            content
                .overlay(alignment: .top) {
                    if cutout != .none {
                        cutoutOverlay(for: cutout)
                    }
                }
        } else {
            content
                .onAppear {
                    deviceCutout = detectDeviceCutout()
                }
        }
    }

    @ViewBuilder
    private func cutoutOverlay(for cutout: DeviceCutout) -> some View {
        GeometryReader { proxy in
            let safeArea = proxy.safeAreaInsets

            cutoutContent()
                .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
                .offset(y: offsetForCutout(cutout, safeAreaTop: safeArea.top))
        }
    }

    private func offsetForCutout(_ cutout: DeviceCutout, safeAreaTop: CGFloat) -> CGFloat {
        switch cutout {
        case .dynamicIsland:
            // Position below the Dynamic Island
            // Dynamic Island bottom is approximately at y = 48 (11 + 37)
            return 11 + 37 + 8 // 8pt padding below island
        case .notch:
            // Position below the notch
            // Notch area is within the safe area, so use safe area top
            return safeAreaTop + 8
        case .none:
            return 0
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Positions content underneath the device's display cutout (Dynamic Island or notch).
    ///
    /// On devices with a Dynamic Island, the content appears just below the island.
    /// On devices with a notch, the content appears just below the notch.
    /// On devices without either, the content is not displayed.
    ///
    /// - Parameters:
    ///   - alignment: The horizontal alignment of the content (default: .center)
    ///   - content: A view builder that creates the content to display
    /// - Returns: A view with the cutout overlay applied
    ///
    /// Example:
    /// ```swift
    /// ContentView()
    ///     .screenshotCutout {
    ///         Text("Recording")
    ///             .font(.caption)
    ///             .foregroundStyle(.red)
    ///     }
    /// ```
    func screenshotCutout<Content: View>(
        alignment: HorizontalAlignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ScreenshotCutoutModifier(alignment: alignment, cutoutContent: content))
    }
}
