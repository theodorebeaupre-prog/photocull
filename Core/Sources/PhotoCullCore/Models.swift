import Foundation

public enum CullDecision: String, Codable, Sendable {
    case keep
    case reject
    case undecided
}

public struct PhotoAnalysis: Codable, Identifiable, Sendable, Equatable {
    public let id: URL
    public var sharpness: Double?
    public var closedEyesProbability: Double?
    public var captureDate: Date?
    public var analysisFailed: Bool

    public init(
        id: URL,
        sharpness: Double? = nil,
        closedEyesProbability: Double? = nil,
        captureDate: Date? = nil,
        analysisFailed: Bool = false
    ) {
        self.id = id
        self.sharpness = sharpness
        self.closedEyesProbability = closedEyesProbability
        self.captureDate = captureDate
        self.analysisFailed = analysisFailed
    }
}

public struct PhotoGroup: Identifiable, Sendable, Equatable {
    public let id: Int
    public var members: [URL]
    public var suggestedKeeper: URL?

    public init(id: Int, members: [URL], suggestedKeeper: URL? = nil) {
        self.id = id
        self.members = members
        self.suggestedKeeper = suggestedKeeper
    }
}
