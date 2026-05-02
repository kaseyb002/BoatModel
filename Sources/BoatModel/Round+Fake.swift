import Foundation

extension Round {
    public static func fake(
        id: String = UUID().uuidString,
        started: Date = .init(),
        players: [Player] = [
            .fake(),
            .fake(),
        ],
        ruleOptions: RuleOptions = .classic
    ) throws -> Round {
        try self.init(
            id: id,
            started: started,
            players: players,
            ruleOptions: ruleOptions
        )
    }
}
