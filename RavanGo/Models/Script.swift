import Foundation
import SwiftData
import SwiftUI

enum ScriptDirection: String, CaseIterable, Codable, Identifiable, Equatable, Sendable {
    case automatic
    case leftToRight
    case rightToLeft

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .automatic: "Automatic"
        case .leftToRight: "Left to Right"
        case .rightToLeft: "Right to Left"
        }
    }

    func resolvedLayoutDirection(for text: String) -> LayoutDirection {
        switch self {
        case .leftToRight: .leftToRight
        case .rightToLeft: .rightToLeft
        case .automatic: Self.detectedLayoutDirection(for: text)
        }
    }

    private static func detectedLayoutDirection(for text: String) -> LayoutDirection {
        var leftToRightCount = 0
        var rightToLeftCount = 0
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0600...0x08FF, 0xFB50...0xFDFF, 0xFE70...0xFEFF:
                rightToLeftCount += 1
            case 0x0041...0x005A, 0x0061...0x007A, 0x00C0...0x02AF:
                leftToRightCount += 1
            default:
                continue
            }
        }
        return rightToLeftCount > leftToRightCount ? .rightToLeft : .leftToRight
    }
}

@Model
final class Script: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var directionRawValue: String

    init(
        id: UUID = UUID(),
        title: String = "Untitled Script",
        content: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        direction: ScriptDirection = .automatic
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.directionRawValue = direction.rawValue
    }

    var direction: ScriptDirection {
        get { ScriptDirection(rawValue: directionRawValue) ?? .automatic }
        set { directionRawValue = newValue.rawValue }
    }

    var resolvedLayoutDirection: LayoutDirection {
        direction.resolvedLayoutDirection(for: content)
    }

    var previewText: String {
        let compact = content
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        return compact.isEmpty ? "No text yet" : String(compact.prefix(120))
    }
}

struct ScriptTransfer: Codable, Equatable, Sendable {
    let id: UUID
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let directionRawValue: String

    init(id: UUID, title: String, content: String, createdAt: Date, updatedAt: Date, direction: ScriptDirection = .automatic) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.directionRawValue = direction.rawValue
    }

    init(script: Script) {
        id = script.id
        title = script.title
        content = script.content
        createdAt = script.createdAt
        updatedAt = script.updatedAt
        directionRawValue = script.directionRawValue
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, content, createdAt, updatedAt, directionRawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        directionRawValue = try container.decodeIfPresent(String.self, forKey: .directionRawValue) ?? ScriptDirection.automatic.rawValue
    }
}
