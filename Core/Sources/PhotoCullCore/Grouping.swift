import Foundation

public struct GroupingItem: Sendable, Equatable {
    public let id: URL
    public let captureDate: Date?

    public init(id: URL, captureDate: Date?) {
        self.id = id
        self.captureDate = captureDate
    }
}

public enum Grouping {
    /// Chronological sweep: a photo joins the current group when it's within
    /// `timeWindow` of the group's last member AND visually within
    /// `distanceThreshold` of the group's anchor (first member).
    public static func groupPhotos(
        _ items: [GroupingItem],
        timeWindow: TimeInterval = 2.0,
        distanceThreshold: Float = 0.6,
        distance: (URL, URL) -> Float?
    ) -> [PhotoGroup] {
        let dated = items
            .filter { $0.captureDate != nil }
            .sorted { $0.captureDate! < $1.captureDate! }
        let undated = items.filter { $0.captureDate == nil }

        var groups: [[GroupingItem]] = []
        for item in dated {
            if let current = groups.last,
               let anchor = current.first,
               let lastDate = current.last?.captureDate,
               let itemDate = item.captureDate,
               itemDate.timeIntervalSince(lastDate) <= timeWindow,
               let d = distance(anchor.id, item.id),
               d <= distanceThreshold {
                groups[groups.count - 1].append(item)
            } else {
                groups.append([item])
            }
        }
        groups.append(contentsOf: undated.map { [$0] })
        return groups.enumerated().map {
            PhotoGroup(id: $0.offset, members: $0.element.map(\.id))
        }
    }
}
