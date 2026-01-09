# UnionScreenshots

A SwiftUI package for controlling view visibility during screen capture and displaying content behind the Dynamic Island.

| Screenshot Mode | Dynamic Island |
|:---:|:---:|
| ![Watermark Demo](watermark-demo.gif) | ![Dynamic Island Demo](demo.gif) |

## Features

- **Screenshot Mode**: Hide or reveal views in screenshots and recordings
- **Screenshot Replacement**: Swap views with different content in screenshots
- **Dynamic Island Background**: Display content behind the Dynamic Island or notch
- Automatic background color sampling for watermarks
- Light/dark mode support

## Requirements

- iOS 18.0+
- Swift 6.2+

## Installation

Add the package to your Xcode project:

```swift
dependencies: [
    .package(url: "https://github.com/unionst/union-screenshots.git", from: "1.2.0")
]
```

## Screenshot Mode

Control how views appear during screen capture.

### Secure

Hide content from screenshots and recordings:

```swift
Text("Secret Code: 1234")
    .screenshotMode(.secure)
```

### Watermark

Show content only in screenshots (hidden during normal use):

```swift
Text("CONFIDENTIAL")
    .screenshotMode(.watermark)
```

The background color is automatically sampled. Watermarks work best on solid, opaque backgrounds.

For explicit control:

```swift
Text("CONFIDENTIAL")
    .screenshotMode(.watermark(background: .white))

Text("CONFIDENTIAL")
    .screenshotMode(.watermark(background: .regularMaterial))
```

### Visible

Use for conditional logic:

```swift
Text("Hello")
    .screenshotMode(isProtected ? .secure : .visible)
```

## Screenshot Replacement

Replace a view with different content in screenshots:

```swift
Text("Secret: 1234")
    .screenshotReplacement {
        Text("Nice try!")
    }
```

## Dynamic Island Background

Display content behind the Dynamic Island or notch.

```swift
ContentView()
    .dynamicIslandBackground {
        Image(.logo)
            .resizable()
            .scaledToFit()
    }
```

With conditional visibility:

```swift
.dynamicIslandBackground(isRecording) {
    HStack {
        Circle().fill(.red).frame(width: 8, height: 8)
        Text("REC").font(.caption2)
    }
}
```

With alignment:

```swift
.dynamicIslandBackground(alignment: .leading) {
    Text("Live").font(.caption2)
}
```

## API

```swift
// Screenshot modes
enum ScreenshotMode {
    case visible
    case secure
    case watermark
    static func watermark(background: some ShapeStyle) -> ScreenshotMode
}

func screenshotMode(_ mode: ScreenshotMode) -> some View

// Screenshot replacement
func screenshotReplacement<Replacement: View>(
    @ViewBuilder _ replacement: () -> Replacement
) -> some View

// Dynamic Island background
func dynamicIslandBackground<Content: View>(
    _ isVisible: Bool = true,
    alignment: HorizontalAlignment = .center,
    @ViewBuilder content: @escaping () -> Content
) -> some View
```

## How It Works

**Screenshot Mode** uses the same mechanism iOS uses for `SecureField` to hide content from screen capture.

**Dynamic Island Background** creates a `UIWindow` overlay at a high window level that appears behind the Dynamic Island cutout.

## License

MIT
