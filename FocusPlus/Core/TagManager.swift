import SwiftUI
import Foundation

// MARK: - Tag Model
struct Tag: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var icon: String
    var color: Color
    
    init(name: String, icon: String, color: Color) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
    }
    
    // ColorのCodable対応
    enum CodingKeys: String, CodingKey {
        case id, name, icon, colorRed, colorGreen, colorBlue, colorOpacity
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        
        let red = try container.decode(Double.self, forKey: .colorRed)
        let green = try container.decode(Double.self, forKey: .colorGreen)
        let blue = try container.decode(Double.self, forKey: .colorBlue)
        let opacity = try container.decode(Double.self, forKey: .colorOpacity)
        color = Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        try container.encode(Double(red), forKey: .colorRed)
        try container.encode(Double(green), forKey: .colorGreen)
        try container.encode(Double(blue), forKey: .colorBlue)
        try container.encode(Double(alpha), forKey: .colorOpacity)
    }
    
    // Equatable実装（Colorの比較は色の値で行う）
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Pomodoro Session Model
struct PomodoroSession: Identifiable, Codable {
    var id = UUID()
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var tagId: UUID?
    var isCompleted: Bool
    
    init(startTime: Date, duration: TimeInterval, tagId: UUID? = nil) {
        self.id = UUID()
        self.startTime = startTime
        self.duration = duration
        self.tagId = tagId
        self.isCompleted = false
    }
}

// MARK: - Tag Manager
class TagManager: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var sessions: [PomodoroSession] = []
    @Published var selectedTag: Tag?
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadTags()
        loadSessions()
        loadSelectedTag()
        
        // 初期化完了の確認
        print("🏷️ TagManager初期化完了 - selectedTag: \(selectedTag?.name ?? "nil"), color: \(selectedTag?.color.description ?? "nil")")
    }
    
    // MARK: - Data Persistence
    private func saveTags() {
        if let encoded = try? JSONEncoder().encode(tags) {
            userDefaults.set(encoded, forKey: "tags")
        }
    }
    
    private func loadTags() {
        if let data = userDefaults.data(forKey: "tags"),
           let decoded = try? JSONDecoder().decode([Tag].self, from: data) {
            tags = decoded
        } else {
            tags = sampleTags
            saveTags()
        }
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: "pomodoroSessions")
        }
    }
    
    private func loadSessions() {
        if let data = userDefaults.data(forKey: "pomodoroSessions"),
           let decoded = try? JSONDecoder().decode([PomodoroSession].self, from: data) {
            sessions = decoded
        } else {
            sessions = []
        }
    }
    
    private func loadSelectedTag() {
        if let data = userDefaults.data(forKey: "selectedTag"),
           let decoded = try? JSONDecoder().decode(Tag.self, from: data) {
            selectedTag = decoded
        }
    }
    
    // MARK: - Tag Operations
    func addTag(_ tag: Tag) {
        tags.append(tag)
        saveTags()
    }
    
    func updateTag(_ tag: Tag, withName name: String, icon: String, color: Color) {
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[index].name = name
            tags[index].icon = icon
            tags[index].color = color
            // 更新されたタグが現在選択されている場合は選択を更新
            if selectedTag?.id == tag.id {
                selectedTag = tags[index]
            }
            saveTags()
        }
    }
    
    func deleteTag(_ tag: Tag) {
        tags.removeAll { $0.id == tag.id }
        // 削除されたタグが現在選択されている場合は選択をクリア
        if selectedTag?.id == tag.id {
            selectedTag = nil
        }
        saveTags()
    }
    
    func selectTag(_ tag: Tag?) {
        selectedTag = tag
        saveSelectedTag()
    }
    
    private func saveSelectedTag() {
        if let encoded = try? JSONEncoder().encode(selectedTag) {
            userDefaults.set(encoded, forKey: "selectedTag")
        } else {
            userDefaults.removeObject(forKey: "selectedTag")
        }
    }
    
    // MARK: - Tag Validation
    func isTagNameValid(_ name: String, excluding tagId: UUID? = nil) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        
        // 同じ名前のタグが既に存在するかチェック（自分自身は除外）
        return !tags.contains { tag in
            tag.name.lowercased() == trimmedName.lowercased() && tag.id != tagId
        }
    }
    
    func getAvailableColors() -> [Color] {
        let allColors: [Color] = [
            .blue, .purple, .green, .orange, .red, .brown, .pink, .gray,
            .indigo, .teal, .mint, .cyan, .yellow
        ]
        return allColors
    }
    
    // MARK: - Session Operations
    func startSession(duration: TimeInterval, tag: Tag? = nil) {
        let session = PomodoroSession(startTime: Date(), duration: duration, tagId: tag?.id)
        sessions.append(session)
        selectedTag = tag
        saveSessions()
    }
    
    func completeCurrentSession() {
        if let index = sessions.lastIndex(where: { !$0.isCompleted }) {
            sessions[index].endTime = Date()
            sessions[index].isCompleted = true
            saveSessions()
        }
    }
    
    func cancelCurrentSession() {
        sessions.removeAll { !$0.isCompleted }
        selectedTag = nil
        saveSessions()
    }
}

// MARK: - Sample Data
let sampleTags = [
    Tag(name: "仕事", icon: "briefcase.fill", color: .blue),
    Tag(name: "プロジェクト", icon: "folder.fill", color: .purple),
    Tag(name: "学習", icon: "book.fill", color: .green),
    Tag(name: "個人", icon: "person.fill", color: .orange),
    Tag(name: "運動", icon: "figure.run", color: .red),
    Tag(name: "読書", icon: "book.closed.fill", color: .brown),
    Tag(name: "創作", icon: "paintpalette.fill", color: .pink),
    Tag(name: "家事", icon: "house.fill", color: .gray)
]
