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
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(tileBackground)
                    .frame(width: isHighlighted ? 88 : 78, height: isHighlighted ? 78 : 68)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(isHighlighted ? .white.opacity(0.92) : .white.opacity(0.14), lineWidth: isHighlighted ? 4 : 1)
                    )
                    .shadow(color: isHighlighted ? .black.opacity(0.32) : .clear, radius: 18, x: 0, y: 10)

                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
                } else {
                    Text(display.fallbackInitial)
                        .font(.system(size: isHighlighted ? 34 : 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 118, height: 84, alignment: .center)

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
            .frame(width: 118, alignment: .leading)
        }
    }

    private var tileBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(nsColor: .controlAccentColor).opacity(0.78),
                Color(nsColor: .systemBlue).opacity(0.62)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
