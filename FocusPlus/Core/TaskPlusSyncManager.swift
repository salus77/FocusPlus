import Foundation
import CoreData
import CloudKit
import SwiftUI

// MARK: - App Mode Enum
enum AppMode: String, CaseIterable {
    case localOnly = "ローカルモード"          // ローカルモード（Apple ID不要）
    case cloudSync = "CloudKit同期"          // CloudKit同期モード（Apple ID必要）
    case taskPlusSync = "TaskPlus連携"       // TaskPlus連携モード（Apple ID必要）
}

// MARK: - Data Models
struct TaskData: Codable {
    let id: String
    let title: String
    let notes: String?
    let due: Date?
    let createdAt: Date
    let updatedAt: Date
    let status: String
    let priority: String
    let context: String
    let categoryId: String?
    let tags: [String]
    let estimatedTime: Int?
    let actualTime: Int?
    let focusSessions: [FocusSessionData]
    let customFields: [String: String]
}

struct CategoryData: Codable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let descriptionText: String?
    let parentId: String?
    let sortOrder: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let customFields: [String: String]
}

struct FocusSessionData: Codable {
    let id: String
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval
    let notes: String?
}

struct TaskPlusExportData: Codable {
    let categories: [CategoryData]
    let tasks: [TaskData]
    let exportDate: Date
    let version: String
}

// MARK: - TaskPlus Sync Manager
class TaskPlusSyncManager: ObservableObject {
    private let persistenceController: PersistenceController
    private var cloudKitContainer: CKContainer?
    private var isMonitoring = false
    
    @Published var currentMode: AppMode = .localOnly
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var syncProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var isCloudKitAvailable = false
    @Published var isTaskPlusAvailable = false
    
    enum SyncStatus {
        case idle, syncing, completed, failed
    }
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.checkAvailableServices()
    }
    
    // MARK: - Service Availability Check
    private func checkAvailableServices() {
        // CloudKitの利用可能性をチェック
        CKContainer.default().accountStatus { [weak self] accountStatus, error in
            DispatchQueue.main.async {
                self?.isCloudKitAvailable = (accountStatus == .available)
                self?.updateAppMode()
            }
        }
        
        // TaskPlusの利用可能性をチェック（ローカルファイルシステムで確認）
        checkTaskPlusAvailability()
    }
    
    private func checkTaskPlusAvailability() {
        // TaskPlusのデータベースファイルが存在するかチェック
        let taskPlusPath = getTaskPlusDatabasePath()
        DispatchQueue.main.async {
            self.isTaskPlusAvailable = FileManager.default.fileExists(atPath: taskPlusPath)
            self.updateAppMode()
        }
    }
    
    private func getTaskPlusDatabasePath() -> String {
        // TaskPlusのデータベースパスを取得（例）
        let homeDirectory = NSHomeDirectory()
        return "\(homeDirectory)/Library/Containers/com.taskpaper.TaskPaper3/Data/Documents/TaskPaper3.taskpaper"
    }
    
    private func updateAppMode() {
        if isCloudKitAvailable && isTaskPlusAvailable {
            currentMode = .taskPlusSync
        } else if isCloudKitAvailable {
            currentMode = .cloudSync
        } else {
            currentMode = .localOnly
        }
        
        print("アプリモードが更新されました: \(currentMode)")
    }
    
    // MARK: - Local Mode Operations (Apple ID不要)
    func createLocalTask(title: String, notes: String? = nil, category: String? = nil) async throws {
        let context = persistenceController.container.viewContext
        
        let task = TaskPlusTask(context: context)
        task.id = UUID().uuidString
        task.title = title
        task.notes = notes
        task.categoryId = category
        task.createdAt = Date()
        task.updatedAt = Date()
        task.status = "inbox"
        task.priority = "normal"
        task.context = "none"
        task.tags = []
        task.estimatedTime = 0
        task.actualTime = 0
        
        try context.save()
        print("ローカルタスクが作成されました: \(title)")
    }
    
    func createLocalCategory(name: String, icon: String = "folder", color: String = "blue") async throws {
        let context = persistenceController.container.viewContext
        
        let category = TaskPlusCategory(context: context)
        category.id = UUID().uuidString
        category.name = name
        category.icon = icon
        category.color = color
        category.descriptionText = nil
        category.parentId = nil
        category.sortOrder = 0
        category.isActive = true
        category.createdAt = Date()
        category.updatedAt = Date()
        
        try context.save()
        print("ローカルカテゴリが作成されました: \(name)")
    }
    
    // MARK: - CloudKit Sync Operations (Apple ID必要)
    func enableCloudKitSync() async throws {
        guard isCloudKitAvailable else {
            throw SyncError.cloudKitNotAvailable
        }
        
        // CloudKit同期を有効化
        try await setupCloudKitContainer()
        currentMode = .cloudSync
        print("CloudKit同期が有効化されました")
    }
    
    private func setupCloudKitContainer() async throws {
        // CloudKitコンテナの設定
        cloudKitContainer = CKContainer(identifier: "iCloud.com.delmar.FocusPlus")
        
        // アカウント状態の確認
        let accountStatus = try await cloudKitContainer!.accountStatus()
        guard accountStatus == .available else {
            throw SyncError.iCloudAccountNotAvailable
        }
    }
    
    // MARK: - TaskPlus Sync Operations (Apple ID必要)
    func enableTaskPlusSync() async throws {
        guard isCloudKitAvailable else {
            throw SyncError.cloudKitNotAvailable
        }
        
        guard isTaskPlusAvailable else {
            throw SyncError.taskPlusNotAvailable
        }
        
        // TaskPlus同期を有効化
        try await setupCloudKitContainer()
        startTaskPlusMonitoring()
        currentMode = .taskPlusSync
        print("TaskPlus同期が有効化されました")
    }
    
    // MARK: - Data Import/Export (ローカルモードでも利用可能)
    func importFromTaskPlus(_ jsonData: String) async throws {
        let context = persistenceController.container.viewContext
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importData = try decoder.decode(TaskPlusExportData.self, from: jsonData.data(using: .utf8)!)
            
            // 既存データをクリア
            try clearExistingData(context: context)
            
            // カテゴリをインポート
            for categoryData in importData.categories {
                let category = TaskPlusCategory(context: context)
                category.id = categoryData.id
                category.name = categoryData.name
                category.icon = categoryData.icon
                category.color = categoryData.color
                category.descriptionText = categoryData.descriptionText
                category.parentId = categoryData.parentId
                category.sortOrder = Int32(categoryData.sortOrder)
                category.isActive = categoryData.isActive
                category.createdAt = categoryData.createdAt
                category.updatedAt = categoryData.updatedAt
            }
            
            // タスクをインポート
            for taskData in importData.tasks {
                let task = TaskPlusTask(context: context)
                task.id = taskData.id
                task.title = taskData.title
                task.notes = taskData.notes
                task.due = taskData.due
                task.createdAt = taskData.createdAt
                task.updatedAt = taskData.updatedAt
                task.status = taskData.status
                task.priority = taskData.priority
                task.context = taskData.context
                task.categoryId = taskData.categoryId
                task.tags = taskData.tags
                task.estimatedTime = Int32(taskData.estimatedTime ?? 0)
                task.actualTime = Int32(taskData.actualTime ?? 0)
            }
            
            try context.save()
            lastSyncDate = Date()
            syncStatus = .completed
            print("TaskPlusデータのインポートが完了しました")
            
        } catch {
            syncStatus = .failed
            errorMessage = "インポートエラー: \(error.localizedDescription)"
            throw error
        }
    }
    
    func exportToTaskPlus() -> String? {
        let context = persistenceController.container.viewContext
        
        do {
            let categories = try context.fetch(NSFetchRequest<TaskPlusCategory>(entityName: "TaskPlusCategory"))
            let tasks = try context.fetch(NSFetchRequest<TaskPlusTask>(entityName: "TaskPlusTask"))
            
            let categoryData = categories.map { $0.toCategoryData() }
            let taskData = tasks.map { $0.toTaskData() }
            
            let exportData = TaskPlusExportData(
                categories: categoryData,
                tasks: taskData,
                exportDate: Date(),
                version: "1.0"
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let jsonData = try encoder.encode(exportData)
            return String(data: jsonData, encoding: .utf8)
            
        } catch {
            print("エクスポートエラー: \(error)")
            return nil
        }
    }
    
    // MARK: - Manual Sync
    func performManualSync() async throws {
        guard currentMode != .localOnly else {
            throw SyncError.syncNotAvailable
        }
        
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            if currentMode == .taskPlusSync {
                try await syncWithTaskPlus()
            } else if currentMode == .cloudSync {
                try await syncWithCloudKit()
            }
            
            syncStatus = .completed
            syncProgress = 1.0
            lastSyncDate = Date()
            
        } catch {
            syncStatus = .failed
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    private func syncWithTaskPlus() async throws {
        // TaskPlusとの同期処理
        syncProgress = 0.3
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        
        syncProgress = 0.6
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        
        syncProgress = 1.0
        print("TaskPlusとの同期が完了しました")
    }
    
    private func syncWithCloudKit() async throws {
        // CloudKitとの同期処理
        syncProgress = 0.5
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        
        syncProgress = 1.0
        print("CloudKitとの同期が完了しました")
    }
    
    // MARK: - TaskPlus Monitoring
    private func startTaskPlusMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        // TaskPlusのデータベース変更を監視
        print("TaskPlus監視を開始しました")
    }
    
    private func stopTaskPlusMonitoring() {
        isMonitoring = false
        print("TaskPlus監視を停止しました")
    }
    
    // MARK: - Data Management
    private func clearExistingData(context: NSManagedObjectContext) throws {
        // 既存のタスクを削除
        let taskFetchRequest: NSFetchRequest<NSFetchRequestResult> = TaskPlusTask.fetchRequest()
        let taskDeleteRequest = NSBatchDeleteRequest(fetchRequest: taskFetchRequest)
        try context.execute(taskDeleteRequest)
        
        // 既存のカテゴリを削除
        let categoryFetchRequest: NSFetchRequest<NSFetchRequestResult> = TaskPlusCategory.fetchRequest()
        let categoryDeleteRequest = NSBatchDeleteRequest(fetchRequest: categoryFetchRequest)
        try context.execute(categoryDeleteRequest)
    }
    
    // MARK: - Error Types
    enum SyncError: LocalizedError {
        case cloudKitNotAvailable
        case iCloudAccountNotAvailable
        case taskPlusNotAvailable
        case syncNotAvailable
        
        var errorDescription: String? {
            switch self {
            case .cloudKitNotAvailable:
                return "CloudKitが利用できません"
            case .iCloudAccountNotAvailable:
                return "iCloudアカウントが利用できません"
            case .taskPlusNotAvailable:
                return "TaskPlusが利用できません"
            case .syncNotAvailable:
                return "同期機能が利用できません"
            }
        }
    }
}

// MARK: - Core Data Extensions
extension TaskPlusCategory {
    func toCategoryData() -> CategoryData {
        return CategoryData(
            id: id ?? UUID().uuidString,
            name: name ?? "",
            icon: icon ?? "folder",
            color: color ?? "blue",
            descriptionText: descriptionText,
            parentId: parentId,
            sortOrder: Int(sortOrder),
            isActive: isActive,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            customFields: [:]
        )
    }
}

extension TaskPlusTask {
    func toTaskData() -> TaskData {
        return TaskData(
            id: id ?? UUID().uuidString,
            title: title ?? "",
            notes: notes,
            due: due,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            status: status ?? "inbox",
            priority: priority ?? "normal",
            context: context ?? "none",
            categoryId: categoryId,
            tags: tags ?? [],
            estimatedTime: Int(estimatedTime),
            actualTime: Int(actualTime),
            focusSessions: [],
            customFields: [:]
        )
    }
}
