import Foundation

public struct RuleOptions: Equatable, Codable, Sendable {
    public var forcedJokerRules: Bool
    public var boatBonus: Bool

    public init(
        forcedJokerRules: Bool = true,
        boatBonus: Bool = true
    ) {
        self.forcedJokerRules = forcedJokerRules
        self.boatBonus = boatBonus
    }

    public static let classic: RuleOptions = .init()
}
