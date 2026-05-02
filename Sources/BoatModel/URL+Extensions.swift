import Foundation

extension URL {
    public static var fakeUserImage: URL {
        .init(string: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?ixlib=rb-4.0.3&auto=format&fit=crop&w=880&q=80")!
    }

    public static var randomImageURL: URL {
        URL(string: "https://picsum.photos/id/\(Int.random(in: 1 ... 1000))/512/512")!
    }

    public static var fakeImageURL: URL {
        URL(string: "https://picsum.photos/id/237/512/512")!
    }
}
