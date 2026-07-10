import PhotoCullCore
import SwiftUI

struct GroupView: View {
    @EnvironmentObject var session: CullSessionViewModel

    private var bursts: [PhotoGroup] {
        session.groups.filter { $0.members.count > 1 }
    }

    var body: some View {
        if bursts.isEmpty {
            Text("No bursts detected.").foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(bursts) { group in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Burst — \(group.members.count) photos").font(.headline)
                        Spacer()
                        if let keeper = group.suggestedKeeper {
                            Button("Keep best, reject rest") {
                                for url in group.members {
                                    session.setDecision(
                                        url == keeper ? .keep : .reject, for: url)
                                }
                            }
                        }
                    }
                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(group.members, id: \.self) { url in
                                ThumbnailView(url: url)
                                    .frame(width: 160, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(
                                                url == group.suggestedKeeper
                                                    ? Color.green : .clear,
                                                lineWidth: 3))
                                    .onTapGesture {
                                        session.setDecision(.keep, for: url)
                                    }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
