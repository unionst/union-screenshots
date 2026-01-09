# UnionScreenshots

A SwiftUI package for displaying content behind the Dynamic Island or notch on iOS devices.

![Demo](demo.gif)

## Features

- Automatically detects device type (Dynamic Island, notch, or neither)
- Creates a window overlay that persists across navigation
- Pass-through touch handling for non-interactive content
- Reactive visibility control

## Requirements

- iOS 18.0+
- Swift 6.2+

## Installation

Add the package to your Xcode project:

```swift
dependencies: [
    .package(url: "https://github.com/unionst/union-screenshots.git", from: "1.0.0")
]
```

## Usage

### Basic Usage

```swift
import UnionScreenshots

struct ContentView: View {
    var body: some View {
        MyAppContent()
            .dynamicIslandBackground {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
            }
    }
}
```

### Conditional Visibility

Control when the overlay is visible:

```swift
struct ContentView: View {
    @State private var showOverlay = false

    var body: some View {
        NavigationStack(path: $path) {
            // ...
        }
        .dynamicIslandBackground(!path.isEmpty) {
            Text("Recording")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}
```

### Custom Alignment

Align content to the leading or trailing edge:

```swift
.dynamicIslandBackground(alignment: .leading) {
    HStack {
        Circle()
            .fill(.red)
            .frame(width: 8, height: 8)
        Text("Live")
            .font(.caption2)
    }
}
```

## API

```swift
func dynamicIslandBackground<Content: View>(
    _ isVisible: Bool = true,
    alignment: HorizontalAlignment = .center,
    @ViewBuilder content: @escaping () -> Content
) -> some View
```

### Parameters

- `isVisible`: Whether the overlay is visible (default: `true`)
- `alignment`: Horizontal alignment of the content (default: `.center`)
- `content`: A view builder that creates the content to display

## How It Works

The modifier creates a separate `UIWindow` overlay at a high window level that sits above your app's content. This allows the content to persist across navigation transitions and appear behind the Dynamic Island cutout.

The overlay automatically:
- Detects the device's display type based on safe area insets
- Positions content at the correct offset for Dynamic Island or notch
- Passes through touches to the underlying content

## License

MIT
