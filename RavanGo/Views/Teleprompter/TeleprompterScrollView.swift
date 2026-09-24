import SwiftUI
import UIKit

@MainActor
struct TeleprompterScrollView: UIViewRepresentable {
    let text: String
    let fontSize: Double
    let lineSpacing: Double
    let margins: Double
    let font: TeleprompterFont
    let alignment: TextAlignmentOption
    let textColor: TextColorOption
    let mirrored: Bool
    let isPlaying: Bool
    let speed: Double
    let restartToken: Int
    let pendingSeek: CGFloat
    let viewportHeight: CGFloat
    let layoutDirection: LayoutDirection
    let onUserPause: @MainActor @Sendable () -> Void
    let onSeekConsumed: @MainActor @Sendable () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onUserPause: onUserPause, onSeekConsumed: onSeekConsumed)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = context.coordinator
        context.coordinator.installContent(in: scrollView)
        context.coordinator.update(
            text: text,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            margins: margins,
            font: font,
            alignment: alignment,
            textColor: textColor,
            mirrored: mirrored,
            isPlaying: isPlaying,
            speed: speed,
            restartToken: restartToken,
            pendingSeek: pendingSeek,
            viewportHeight: viewportHeight,
            layoutDirection: layoutDirection
        )
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.update(
            text: text,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            margins: margins,
            font: font,
            alignment: alignment,
            textColor: textColor,
            mirrored: mirrored,
            isPlaying: isPlaying,
            speed: speed,
            restartToken: restartToken,
            pendingSeek: pendingSeek,
            viewportHeight: viewportHeight,
            layoutDirection: layoutDirection
        )
    }

    static func dismantleUIView(_ scrollView: UIScrollView, coordinator: Coordinator) {
        coordinator.invalidate()
    }

    @MainActor
    final class Coordinator: NSObject, UIScrollViewDelegate {
        private struct TextConfiguration: Equatable {
            let text: String
            let fontSize: Double
            let lineSpacing: Double
            let margins: Double
            let font: TeleprompterFont
            let alignment: TextAlignmentOption
            let textColor: TextColorOption
            let mirrored: Bool
            let viewportHeight: CGFloat
            let layoutDirection: LayoutDirection
        }

        private let onUserPause: @MainActor @Sendable () -> Void
        private let onSeekConsumed: @MainActor @Sendable () -> Void
        private weak var scrollView: UIScrollView?
        private var hostController: UIHostingController<TeleprompterTextView>?
        private var displayLink: CADisplayLink?
        private var lastTimestamp: CFTimeInterval?
        private var lastTextConfiguration: TextConfiguration?
        private var pendingProgressCorrection: CGFloat?
        private var correctionScheduled = false
        private var currentSpeed = 1.0
        private var playing = false
        private var lastRestartToken = 0

        init(
            onUserPause: @escaping @MainActor @Sendable () -> Void,
            onSeekConsumed: @escaping @MainActor @Sendable () -> Void
        ) {
            self.onUserPause = onUserPause
            self.onSeekConsumed = onSeekConsumed
        }

        func invalidate() {
            stopDisplayLink()
            hostController = nil
            scrollView = nil
        }

        func installContent(in scrollView: UIScrollView) {
            self.scrollView = scrollView
            let initialTextView = TeleprompterTextView(
                text: "", fontSize: 44, lineSpacing: 12, margins: 28,
                font: .system, alignment: .leading, textColor: .white,
                mirrored: false, viewportHeight: 600, layoutDirection: .leftToRight
            )
            let host = UIHostingController(rootView: initialTextView)
            host.view.backgroundColor = .clear
            host.view.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                host.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                host.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
            ])
            hostController = host
        }

        func update(
            text: String,
            fontSize: Double,
            lineSpacing: Double,
            margins: Double,
            font: TeleprompterFont,
            alignment: TextAlignmentOption,
            textColor: TextColorOption,
            mirrored: Bool,
            isPlaying: Bool,
            speed: Double,
            restartToken: Int,
            pendingSeek: CGFloat,
            viewportHeight: CGFloat,
            layoutDirection: LayoutDirection
        ) {
            guard let scrollView else { return }
            let configuration = TextConfiguration(
                text: text,
                fontSize: fontSize,
                lineSpacing: lineSpacing,
                margins: margins,
                font: font,
                alignment: alignment,
                textColor: textColor,
                mirrored: mirrored,
                viewportHeight: viewportHeight,
                layoutDirection: layoutDirection
            )

            currentSpeed = speed
            let isRestart = restartToken != lastRestartToken
            if configuration != lastTextConfiguration {
                let progress = isRestart ? nil : scrollProgress(in: scrollView)
                lastTextConfiguration = configuration
                hostController?.rootView = TeleprompterTextView(
                    text: text,
                    fontSize: fontSize,
                    lineSpacing: lineSpacing,
                    margins: margins,
                    font: font,
                    alignment: alignment,
                    textColor: textColor,
                    mirrored: mirrored,
                    viewportHeight: viewportHeight,
                    layoutDirection: layoutDirection
                )
                if let progress {
                    pendingProgressCorrection = progress
                    scheduleProgressCorrection()
                }
            }

            if restartToken != lastRestartToken {
                lastRestartToken = restartToken
                scrollView.setContentOffset(.zero, animated: false)
                lastTimestamp = nil
            }

            if pendingSeek != 0 {
                let minimum = -scrollView.adjustedContentInset.top
                let maximum = max(minimum, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
                let offset = min(max(scrollView.contentOffset.y + pendingSeek, minimum), maximum)
                scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
                DispatchQueue.main.async { [onSeekConsumed] in
                    onSeekConsumed()
                }
            }

            playing = isPlaying
            if isPlaying {
                startDisplayLink()
            } else {
                stopDisplayLink()
            }
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            pendingProgressCorrection = nil
            if playing {
                playing = false
                stopDisplayLink()
                onUserPause()
            }
        }

        private func startDisplayLink() {
            guard displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(step(_:)))
            if #available(iOS 15.0, *) {
                link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 60)
            }
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        private func stopDisplayLink() {
            displayLink?.invalidate()
            displayLink = nil
            lastTimestamp = nil
        }

        private func scrollProgress(in scrollView: UIScrollView) -> CGFloat? {
            let minimum = -scrollView.adjustedContentInset.top
            let maximum = max(minimum, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
            let range = maximum - minimum
            guard range > 1 else { return nil }
            return min(max((scrollView.contentOffset.y - minimum) / range, 0), 1)
        }

        private func scheduleProgressCorrection() {
            guard !correctionScheduled else { return }
            correctionScheduled = true
            DispatchQueue.main.async { [weak self] in
                guard let self, let scrollView = self.scrollView else { return }
                self.correctionScheduled = false
                guard let progress = self.pendingProgressCorrection else { return }
                self.pendingProgressCorrection = nil

                let minimum = -scrollView.adjustedContentInset.top
                let maximum = max(minimum, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
                let offset = minimum + ((maximum - minimum) * progress)
                scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
            }
        }

        @objc private func step(_ displayLink: CADisplayLink) {
            guard let scrollView, playing else { return }
            guard let previous = lastTimestamp else {
                lastTimestamp = displayLink.timestamp
                return
            }
            let delta = min(displayLink.timestamp - previous, 0.05)
            lastTimestamp = displayLink.timestamp

            let pointsPerSecond = 58.0 * currentSpeed
            let nextOffset = scrollView.contentOffset.y + CGFloat(delta * pointsPerSecond)
            let maximum = max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
            if nextOffset >= maximum {
                scrollView.setContentOffset(CGPoint(x: 0, y: maximum), animated: false)
                playing = false
                stopDisplayLink()
                onUserPause()
            } else {
                scrollView.setContentOffset(CGPoint(x: 0, y: nextOffset), animated: false)
            }
        }
    }
}
