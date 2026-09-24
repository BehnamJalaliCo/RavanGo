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

    func resolvedLayoutDirection(for text: String, fallback: LayoutDirection = .leftToRight) -> LayoutDirection {
        switch self {
        case .leftToRight: .leftToRight
        case .rightToLeft: .rightToLeft
        case .automatic: Self.detectedLayoutDirection(for: text, fallback: fallback)
        }
    }

    private static func detectedLayoutDirection(for text: String, fallback: LayoutDirection) -> LayoutDirection {
        for scalar in text.unicodeScalars {
            let isRightToLeftRange = switch scalar.value {
            case 0x0590...0x05FF, 0x0600...0x08FF, 0xFB1D...0xFDFF, 0xFE70...0xFEFF:
                true
            default:
                false
            }
            if isRightToLeftRange && CharacterSet.letters.contains(scalar) {
                return .rightToLeft
            }
            if CharacterSet.letters.contains(scalar) {
                return .leftToRight
            }
        }
        return fallback
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

    func resolvedTitleLayoutDirection(fallback: LayoutDirection) -> LayoutDirection {
        direction.resolvedLayoutDirection(for: title, fallback: fallback)
    }

    func resolvedContentLayoutDirection(fallback: LayoutDirection) -> LayoutDirection {
        direction.resolvedLayoutDirection(for: content, fallback: fallback)
    }

    var resolvedLayoutDirection: LayoutDirection {
        direction.resolvedLayoutDirection(for: content, fallback: .leftToRight)
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
