import Foundation

public typealias PlayerID = String

public struct Player: Equatable, Codable, Sendable, Identifiable {
    public let id: PlayerID
    public var name: String
    public var imageURL: URL?
    public var scorecard: Scorecard

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL = "imageUrl"
        case scorecard
    }

    public init(
        id: PlayerID,
        name: String,
        imageURL: URL?,
        scorecard: Scorecard = .init()
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.scorecard = scorecard
    }
}
