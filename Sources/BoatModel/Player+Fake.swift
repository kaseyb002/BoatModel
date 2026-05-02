import Foundation

extension Player {
    public static func fake(
        id: PlayerID = UUID().uuidString,
        name: String = Lorem.fullName,
        imageURL: URL? = .randomImageURL,
        scorecard: Scorecard = .init()
    ) -> Player {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            scorecard: scorecard
        )
    }
}
