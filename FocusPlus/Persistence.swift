//
//  Persistence.swift
//  FocusPlus
//
//  Created by Yasutaka Otsubo on 2025/08/22.
//

import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "FocusPlus")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // CloudKit同期の設定
        guard let description = container.persistentStoreDescriptions.first else {
            print("警告: 永続化ストアの説明を取得できませんでした")
            return
        }
        
        // まずローカルストレージとして設定
        description.setOption(false as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(false as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // iCloudアカウントの状態を確認
        CKContainer.default().accountStatus { accountStatus, error in
            DispatchQueue.main.async {
                if accountStatus == .available {
                    // iCloudアカウントが利用可能な場合のみCloudKit同期を有効化
                    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                    
                    // CloudKitコンテナの設定
                    description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                        containerIdentifier: "iCloud.com.delmar.FocusPlus"
                    )
                    
                    print("CloudKit同期が有効化されました")
                } else {
                    // iCloudアカウントが利用できない場合はローカルストレージのみで動作
                    print("iCloudアカウントが利用できません。ローカルストレージのみで動作します")
                }
            }
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // CloudKit接続エラーの場合は、ローカルストレージのみで動作
                print("CloudKit接続エラー: \(error.localizedDescription)")
                print("ローカルストレージのみで動作します")
                
                // エラーの詳細をログ出力
                if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                    print("詳細エラー: \(underlyingError.localizedDescription)")
                }
            } else {
                print("永続化ストアの読み込みが成功しました")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // CloudKit同期の監視を設定
        setupCloudKitSyncMonitoring()
    }
    
    // MARK: - CloudKit Sync Monitoring
    private func setupCloudKitSyncMonitoring() {
        // リモート変更通知の監視
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { _ in
            // リモート変更があった場合、UIを更新
            DispatchQueue.main.async {
                self.container.viewContext.refreshAllObjects()
            }
        }
        
        // CloudKitアカウント状態の監視
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.CKAccountChanged,
            object: nil,
            queue: .main
        ) { _ in
            // iCloudアカウントの状態が変更された場合の処理
            self.handleCloudKitAccountChange()
        }
    }
    
    private func handleCloudKitAccountChange() {
        // iCloudアカウントの状態を確認
        CKContainer.default().accountStatus { accountStatus, error in
            DispatchQueue.main.async {
                switch accountStatus {
                case .available:
                    print("CloudKit: iCloudアカウントが利用可能です")
                case .noAccount:
                    print("CloudKit: iCloudアカウントが設定されていません")
                case .restricted:
                    print("CloudKit: iCloudアカウントが制限されています")
                case .couldNotDetermine:
                    print("CloudKit: iCloudアカウントの状態を確認できません")
                case .temporarilyUnavailable:
                    print("CloudKit: iCloudアカウントが一時的に利用できません")
                @unknown default:
                    print("CloudKit: 不明なアカウント状態")
                }
            }
        }
    }
    
    // MARK: - CloudKit Sync Management
    private func disableCloudKitSync() {
        // CloudKit同期を無効化
        guard let description = container.persistentStoreDescriptions.first else { return }
        
        // CloudKitオプションを無効化
        description.setOption(false as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(false as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.cloudKitContainerOptions = nil
        
        print("CloudKit同期が無効化されました")
    }
    
    // MARK: - TaskPlus Integration Methods
    func syncTaskPlusData() {
        // TaskPlusからのデータ同期を実行
        let context = container.viewContext
        
        // 既存のTaskPlusデータを取得
        let fetchRequest: NSFetchRequest<TaskPlusTask> = TaskPlusTask.fetchRequest()
        
        do {
            let existingTasks = try context.fetch(fetchRequest)
            print("CloudKit: 既存のTaskPlusタスク数: \(existingTasks.count)")
            
            // 同期状態をログ出力
            for task in existingTasks {
                print("CloudKit: タスク '\(task.title ?? "Unknown")' - 最終更新: \(task.updatedAt ?? Date())")
            }
        } catch {
            print("CloudKit: タスク取得エラー: \(error)")
        }
    }
    
    func createSampleTaskPlusData() {
        let context = container.viewContext
        
        // サンプルカテゴリを作成
        let category = TaskPlusCategory(context: context)
        category.id = UUID().uuidString
        category.name = "サンプルカテゴリ"
        category.icon = "folder"
        category.color = "blue"
        category.createdAt = Date()
        category.updatedAt = Date()
        category.isActive = true
        
        // サンプルタスクを作成
        let task = TaskPlusTask(context: context)
        task.id = UUID().uuidString
        task.title = "サンプルタスク"
        task.notes = "これはCloudKit同期のテスト用タスクです"
        task.createdAt = Date()
        task.updatedAt = Date()
        task.status = "inbox"
        task.priority = "normal"
        task.context = "none"
        task.category = category
        
        // サンプルフォーカスセッションを作成
        let session = TaskPlusFocusSession(context: context)
        session.id = UUID().uuidString
        session.startTime = Date()
        session.focusMode = "pomodoro"
        session.interruptions = 0
        session.energyLevel = 7
        session.productivity = 8
        session.task = task
        
        do {
            try context.save()
            print("CloudKit: サンプルデータの作成が完了しました")
        } catch {
            print("CloudKit: サンプルデータ作成エラー: \(error)")
        }
    }
}
