import PhotoCullCore
import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var session: CullSessionViewModel
    @State private var index = 0

    var body: some View {
        VStack(spacing: 8) {
            if session.photos.isEmpty {
                Text("No photos analyzed yet.").foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let photo = session.photos[boundedIndex]
                ThumbnailView(url: photo.id, maxPixel: 2048)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                HStack(spacing: 8) {
                    Text(photo.id.lastPathComponent).font(.headline)
                    if photo.analysisFailed { Badge(text: "unanalyzed", color: .gray) }
                    if !photo.analysisFailed && Scoring.sharpnessScore(photo.sharpness) < 0.25 {
                        Badge(text: "blurry", color: .orange)
                    }
                    if (photo.closedEyesProbability ?? 0) > 0.6 {
                        Badge(text: "eyes closed", color: .red)
                    }
                    if session.decision(for: photo.id) == .undecided,
                       let suggested = session.suggestedDecision(for: photo.id) {
                        Text("suggested: \(suggested == .keep ? "keep" : "reject")")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    Text(decisionLabel)
                    Text("\(boundedIndex + 1) / \(session.photos.count)")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                Text("K = keep    X = reject    ← → = navigate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)
            }
        }
        .focusable()
        .onKeyPress(.rightArrow) { move(1); return .handled }
        .onKeyPress(.leftArrow) { move(-1); return .handled }
        .onKeyPress(KeyEquivalent("k")) { decide(.keep); return .handled }
        .onKeyPress(KeyEquivalent("x")) { decide(.reject); return .handled }
    }

    private var boundedIndex: Int {
        min(max(0, index), session.photos.count - 1)
    }

    private var decisionLabel: String {
        switch session.decision(for: session.photos[boundedIndex].id) {
        case .keep: return "✓ keep"
        case .reject: return "✗ reject"
        case .undecided: return "—"
        }
    }

    private func move(_ delta: Int) {
        guard !session.photos.isEmpty else { return }
        index = min(max(0, boundedIndex + delta), session.photos.count - 1)
    }

    private func decide(_ d: CullDecision) {
        guard !session.photos.isEmpty else { return }
        session.setDecision(d, for: session.photos[boundedIndex].id)
        move(1)
    }
}
