

import Foundation

struct SleepSession: Codable, Equatable {
    let id: UUID
    let start: Date
    let end: Date
    var duration: TimeInterval { end.timeIntervalSince(start) }

    enum CodingKeys: String, CodingKey { case id, start, end }

    init(id: UUID = UUID(), start: Date, end: Date) {
        self.id = id
        self.start = start
        self.end = end
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        start = try c.decode(Date.self, forKey: .start)
        end = try c.decode(Date.self, forKey: .end)
    }
}
