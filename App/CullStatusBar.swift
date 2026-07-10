import PhotoCullCore
import SwiftUI

/// Goal-gradient status bar: the completed analysis counts as step one, so the
/// progress never reads zero — momentum instead of a blank slate.
struct CullStatusBar: View {
    @EnvironmentObject var session: CullSessionViewModel

    var body: some View {
        if !session.photos.isEmpty {
            HStack(spacing: 12) {
                ProgressView(value: session.cullProgress)
                    .frame(maxWidth: 220)
                Text("Analyzed ✓ · \(session.keptCount) kept · \(session.rejectedCount) rejected · \(max(0, session.photos.count - session.decidedCount)) to go")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}
