import PhotoCullCore
import SwiftUI

struct GridView: View {
    @EnvironmentObject var session: CullSessionViewModel
    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 8)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(session.photos) { photo in
                    PhotoCell(photo: photo)
                }
            }
            .padding(8)
        }
    }
}

struct PhotoCell: View {
    @EnvironmentObject var session: CullSessionViewModel
    let photo: PhotoAnalysis

    private var isBlurry: Bool {
        !photo.analysisFailed && Scoring.sharpnessScore(photo.sharpness) < 0.25
    }
    private var hasClosedEyes: Bool {
        (photo.closedEyesProbability ?? 0) > 0.6
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ThumbnailView(url: photo.id)
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            HStack(spacing: 4) {
                if photo.analysisFailed { Badge(text: "unanalyzed", color: .gray) }
                if isBlurry { Badge(text: "blurry", color: .orange) }
                if hasClosedEyes { Badge(text: "eyes closed", color: .red) }
            }
            .padding(4)
        }
        .overlay(alignment: .bottomTrailing) {
            switch session.decision(for: photo.id) {
            case .keep:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green).padding(4)
            case .reject:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red).padding(4)
            case .undecided:
                EmptyView()
            }
        }
        .overlay(alignment: .bottomLeading) {
            if session.decision(for: photo.id) == .undecided,
               let suggested = session.suggestedDecision(for: photo.id) {
                Badge(
                    text: suggested == .keep ? "suggested keep" : "suggested reject",
                    color: suggested == .keep ? .green : .orange)
                    .padding(4)
            }
        }
        .contextMenu {
            Button("Keep") { session.setDecision(.keep, for: photo.id) }
            Button("Reject") { session.setDecision(.reject, for: photo.id) }
            Button("Clear") { session.setDecision(.undecided, for: photo.id) }
        }
    }
}
