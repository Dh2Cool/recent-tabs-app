import AppKit
import SwiftUI

public struct SwitcherOverlayView: View {
    private let state: SwitcherState
    @ObservedObject private var faviconProvider: FaviconProvider

    public init(state: SwitcherState, faviconProvider: FaviconProvider) {
        self.state = state
        self.faviconProvider = faviconProvider
    }

    public var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(Array(state.tabs.enumerated()), id: \.element.id) { index, tab in
                    SwitcherTabTile(
                        display: TabDisplayModel(tab: tab),
                        image: faviconProvider.image(for: tab),
                        isHighlighted: index == state.highlightedIndex
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Text("Safari Recent Tabs")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.45), radius: 32, x: 0, y: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .padding(8)
    }
}

private struct SwitcherTabTile: View {
    let display: TabDisplayModel
    let image: NSImage?
    let isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let image {
                    FaviconImage(image: image, isHighlighted: isHighlighted)
                } else {
                    FallbackIcon(initial: display.fallbackInitial, isHighlighted: isHighlighted)
                }
            }
            .frame(width: SwitcherOverlayMetrics.tileWidth, height: 86, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(display.title)
                    .font(.system(size: 12, weight: isHighlighted ? .bold : .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(display.domain)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: SwitcherOverlayMetrics.tileWidth, alignment: .leading)
        }
    }
}

private struct FaviconImage: View {
    let image: NSImage
    let isHighlighted: Bool

    var body: some View {
        ZStack {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.14))
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.92), lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.32), radius: 18, x: 0, y: 10)
            }

            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
        }
    }
}

private struct FallbackIcon: View {
    let initial: String
    let isHighlighted: Bool

    var body: some View {
        ZStack {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.14))
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.92), lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.32), radius: 18, x: 0, y: 10)
            }

            Text(initial)
                .font(.system(size: isHighlighted ? 34 : 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
        }
    }
}
