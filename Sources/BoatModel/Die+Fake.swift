import Foundation

extension Die {
    public static func fake(
        id: DieID = Int.random(in: 0 ... 4),
        value: DieValue = .allCases.randomElement()!
    ) -> Die {
        .init(id: id, value: value)
    }
}
