import Foundation

public typealias DieID = Int

public struct Die: Equatable, Codable, Sendable, Identifiable {
    public let id: DieID
    public var value: DieValue

    public init(id: DieID, value: DieValue) {
        self.id = id
        self.value = value
    }
}
