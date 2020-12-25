import UIKit

var str = "Hello, playground"

//Hererogenous
class Feed: Codable {
    var posts: [Post] = []
    init() {
        //
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.posts = try container.decodingHetrogenousArray(family: PostClassFamily.self, forKey: .posts)
    }
}
class Post: Codable,CustomStringConvertible {
    var date = Date()
    var id: String
    var type: String
    init(type: String) {
        self.id = UUID().uuidString
        self.type = type
    }
    
    var description: String {
        return "Post ???"
    }
}

class TextPost: Post {
    var text: String
    init(text: String) {
        self.text = text
        super.init(type: "text")
    }
    enum CodingKeys: String, CodingKey {
        case text
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
    }
    
    override var description: String {
        return "text \(text)"
    }
}

class ImagePost: Post {
    var imageUrl: URL
    init(url: URL) {
        self.imageUrl = url
        super.init(type: "image")
    }
    enum CodingKeys: String, CodingKey {
        case imageUrl
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageUrl = try container.decode(URL.self, forKey: .imageUrl)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageUrl, forKey: .imageUrl)
    }
    
    override var description: String {
        return "imageUrl: \(imageUrl)"
    }
}

protocol DecodableClassFamily: Decodable {
    associatedtype BaseType: Decodable
    static var descriminator: Descriminator {get}
    func getType() -> BaseType.Type
}

enum Descriminator: String, CodingKey {
    case type = "type"
}

enum PostClassFamily: String,DecodableClassFamily {
    typealias BaseType = Post
    case text
    case image
    static var descriminator: Descriminator { return .type}
    
    func getType() -> Post.Type {
        switch self {
        case .text:
            return TextPost.self
        case .image:
            return ImagePost.self
        }
    }
}

let feed = Feed()
feed.posts.append(TextPost(text: "text post"))
feed.posts.append(ImagePost(url: URL(string: "twitter.com/pranith")!))

let data = try JSONEncoder().encode(feed)
let dataString = String(data: data, encoding: .utf8)!
print(dataString)

let decodedData = try JSONDecoder().decode(Feed.self, from: data)
print(decodedData)
for post in decodedData.posts {
    print("==>", post.description,post.id,post.type)
}

extension KeyedDecodingContainer {
    func decodingHetrogenousArray<F: DecodableClassFamily>(family: F.Type,forKey key: K) throws -> [F.BaseType] {
        var container = try nestedUnkeyedContainer(forKey: key)
        var containerCopy = container
        var items: [F.BaseType] = []
        while !container.isAtEnd {
            let typeContainer = try container.nestedContainer(keyedBy: Descriminator.self)
            let family = try typeContainer.decode(F.self, forKey: PostClassFamily.descriminator)
            if let type = family.getType() as? F.BaseType.Type {
                let item = try containerCopy.decode(type)
                items.append(item)
            } else {
                let _ = try containerCopy.decode(Post.self)
            }
        }
        return items
    }
}
