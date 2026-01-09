//
//  _ScreenshotExample.swift
//  UnionScreenshots
//
//  Created by Union on 1/9/26.
//

import SwiftUI

/// An example view for testing all UnionScreenshots features.
///
/// This view demonstrates:
/// - Screenshot protection using `SecureView`
/// - Screenshot protection using `.secure()` modifier
/// - Dynamic Island background overlay
public struct _ScreenshotExample: View {

    @State private var showDynamicIslandOverlay = true
    @State private var secretText = "Secret: 1234-5678"

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                screenshotProtectionSection
                dynamicIslandSection
                instructionsSection
            }
            .navigationTitle("UnionScreenshots")
        }
        .dynamicIslandBackground(showDynamicIslandOverlay) {
            HStack(spacing: 4) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("REC")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Screenshot Protection Section

    private var screenshotProtectionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Protected Content")
                    .font(.headline)

                SecureView {
                    VStack(spacing: 8) {
                        Text("This text is protected")
                            .font(.body)
                            .fontWeight(.medium)
                        Text(secretText)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 12) {
                Text("Using Modifier")
                    .font(.headline)

                Text("Also protected via .secure()")
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .secure()
            }
            .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 12) {
                Text("Unprotected Content")
                    .font(.headline)

                Text("This text WILL appear in screenshots")
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.vertical, 8)
        } header: {
            Text("Screenshot Protection")
        } footer: {
            Text("Take a screenshot to test. Protected content will appear blank in the screenshot.")
        }
    }

    // MARK: - Dynamic Island Section

    private var dynamicIslandSection: some View {
        Section {
            Toggle("Show Dynamic Island Overlay", isOn: $showDynamicIslandOverlay)

            VStack(alignment: .leading, spacing: 8) {
                Text("Current Display Type")
                    .font(.headline)

                HStack {
                    let displayType = detectDisplayType()
                    Circle()
                        .fill(displayType == .none ? .red : .green)
                        .frame(width: 10, height: 10)
                    Text(displayTypeName(displayType))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Dynamic Island Background")
        } footer: {
            Text("The red 'REC' indicator appears below the Dynamic Island when enabled.")
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(number: 1, text: "Take a screenshot of this screen")
                instructionRow(number: 2, text: "Check the screenshot in Photos")
                instructionRow(number: 3, text: "Protected content should be blank")
                instructionRow(number: 4, text: "Unprotected content should be visible")
            }
            .padding(.vertical, 8)
        } header: {
            Text("How to Test")
        }
    }

    // MARK: - Helpers

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(.blue))

            Text(text)
                .font(.body)
        }
    }

    private func displayTypeName(_ type: DisplayType) -> String {
        switch type {
        case .dynamicIsland: return "Dynamic Island"
        case .notch: return "Notch"
        case .none: return "None"
        }
    }
}

#Preview {
    _ScreenshotExample()
}
