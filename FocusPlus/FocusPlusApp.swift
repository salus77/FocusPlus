//
//  FocusPlusApp.swift
//  FocusPlus
//
//  Created by Yasutaka Otsubo on 2025/08/22.
//

import SwiftUI
import UserNotifications

@main
struct FocusPlusApp: App {
    let persistenceController = PersistenceController.shared
    let taskPlusSyncManager: TaskPlusSyncManager
    
    init() {
        // TaskPlusSyncManagerの初期化
        self.taskPlusSyncManager = TaskPlusSyncManager(persistenceController: persistenceController)
        
        // 通知権限の要求
        requestNotificationPermissions()
        // 通知設定の初期化
        setupNotifications()
        // アプリ起動時にバッジをクリア
        clearBadge()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(taskPlusSyncManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // アプリがアクティブになった時にバッジをクリア
                    clearBadge()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // アプリがフォアグラウンドに入る時にバッジをクリア
                    clearBadge()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // アプリがアクティブになった時にバッジをクリア
                    clearBadge()
                }
        }
    }
    
    // MARK: - Notification Setup
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("通知権限が許可されました")
            } else if let error = error {
                print("通知権限の要求でエラーが発生しました: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupNotifications() {
        // 通知カテゴリの設定
        let startTimerAction = UNNotificationAction(
            identifier: "START_TIMER",
            title: "タイマー開始",
            options: [.foreground]
        )
        
        let pauseTimerAction = UNNotificationAction(
            identifier: "PAUSE_TIMER",
            title: "タイマー一時停止",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: "FOCUSPLUS_TIMER",
            actions: [startTimerAction, pauseTimerAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // MARK: - Badge Management
    private func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
