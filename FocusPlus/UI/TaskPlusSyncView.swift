import SwiftUI
import CloudKit

struct TaskPlusSyncView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var syncManager: TaskPlusSyncManager
    @State private var showingImportSheet = false
    @State private var showingExportSheet = false
    @State private var importText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAutoSyncEnabled = true
    
    var body: some View {
        List {
            // MARK: - App Mode Section
            Section("アプリモード") {
                HStack {
                    Image(systemName: appModeIcon)
                        .foregroundColor(appModeColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appModeTitle)
                            .font(.headline)
                        Text(appModeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(syncManager.currentMode.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(appModeColor.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // MARK: - Service Status Section
            Section("サービス状態") {
                HStack {
                    Image(systemName: syncManager.isCloudKitAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(syncManager.isCloudKitAvailable ? .green : .red)
                    Text("iCloud/CloudKit")
                    Spacer()
                    Text(syncManager.isCloudKitAvailable ? "利用可能" : "利用不可")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: syncManager.isTaskPlusAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(syncManager.isTaskPlusAvailable ? .green : .red)
                    Text("TaskPlus")
                    Spacer()
                    Text(syncManager.isTaskPlusAvailable ? "利用可能" : "利用不可")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // MARK: - Sync Status Section (CloudKit利用可能な場合のみ)
            if syncManager.currentMode != .localOnly {
                Section("同期状態") {
                    HStack {
                        Image(systemName: syncStatusIcon)
                            .foregroundColor(syncStatusColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(syncStatusTitle)
                                .font(.headline)
                            if syncManager.syncStatus == .syncing {
                                ProgressView(value: syncManager.syncProgress)
                                    .progressViewStyle(LinearProgressViewStyle())
                            }
                        }
                        Spacer()
                        if let lastSync = syncManager.lastSyncDate {
                            Text(lastSync, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if syncManager.syncStatus == .syncing {
                        HStack {
                            Text("同期中...")
                            Spacer()
                            Text("\(Int(syncManager.syncProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // MARK: - Local Mode Features (Apple ID不要)
            Section("ローカル機能") {
                Button(action: {
                    Task {
                        do {
                            try await syncManager.createLocalTask(title: "新しいタスク", notes: "タスクの詳細")
                            alertMessage = "ローカルタスクが作成されました"
                            showingAlert = true
                        } catch {
                            alertMessage = "エラー: \(error.localizedDescription)"
                            showingAlert = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                        Text("サンプルタスクを作成")
                    }
                }
                
                Button(action: {
                    Task {
                        do {
                            try await syncManager.createLocalCategory(name: "新しいカテゴリ")
                            alertMessage = "ローカルカテゴリが作成されました"
                            showingAlert = true
                        } catch {
                            alertMessage = "エラー: \(error.localizedDescription)"
                            showingAlert = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(.blue)
                        Text("サンプルカテゴリを作成")
                    }
                }
            }
            
            // MARK: - Data Import/Export Section
            Section("データのインポート/エクスポート") {
                Button(action: { showingImportSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                        Text("TaskPlusからデータをインポート")
                    }
                }
                
                Button(action: { showingExportSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.orange)
                        Text("TaskPlus形式でデータをエクスポート")
                    }
                }
            }
            
            // MARK: - CloudKit Sync Section (Apple ID必要)
            if syncManager.isCloudKitAvailable {
                Section("CloudKit同期") {
                    Button(action: {
                        Task {
                            do {
                                try await syncManager.enableCloudKitSync()
                                alertMessage = "CloudKit同期が有効化されました"
                                showingAlert = true
                            } catch {
                                alertMessage = "エラー: \(error.localizedDescription)"
                                showingAlert = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("CloudKit同期を有効化")
                        }
                    }
                    .disabled(syncManager.currentMode == .cloudSync || syncManager.currentMode == .taskPlusSync)
                }
            }
            
            // MARK: - TaskPlus Sync Section (Apple ID必要)
            if syncManager.isCloudKitAvailable && syncManager.isTaskPlusAvailable {
                Section("TaskPlus連携") {
                    Button(action: {
                        Task {
                            do {
                                try await syncManager.enableTaskPlusSync()
                                alertMessage = "TaskPlus連携が有効化されました"
                                showingAlert = true
                            } catch {
                                alertMessage = "エラー: \(error.localizedDescription)"
                                showingAlert = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "link.circle")
                                .foregroundColor(.purple)
                            Text("TaskPlus連携を有効化")
                        }
                    }
                    .disabled(syncManager.currentMode == .taskPlusSync)
                    
                    if syncManager.currentMode == .taskPlusSync {
                        Button(action: {
                            Task {
                                do {
                                    try await syncManager.performManualSync()
                                    alertMessage = "手動同期が完了しました"
                                    showingAlert = true
                                } catch {
                                    alertMessage = "エラー: \(error.localizedDescription)"
                                    showingAlert = true
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.green)
                                Text("手動同期を実行")
                            }
                        }
                        .disabled(syncManager.syncStatus == .syncing)
                    }
                }
            }
            
            // MARK: - Help Section
            Section("ヘルプ") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("アプリモードについて")
                        .font(.headline)
                    Text("• ローカルモード: Apple ID不要、基本的な機能のみ")
                    Text("• CloudKit同期: iCloudアカウント必要、デバイス間同期")
                    Text("• TaskPlus連携: iCloudアカウント必要、完全同期連携")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("TaskPlus連携")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完了") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportSheet(importText: $importText, syncManager: syncManager)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(syncManager: syncManager)
        }
        .alert("情報", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Computed Properties
    private var appModeIcon: String {
        switch syncManager.currentMode {
        case .localOnly:
            return "iphone"
        case .cloudSync:
            return "icloud"
        case .taskPlusSync:
            return "link.circle"
        }
    }
    
    private var appModeColor: Color {
        switch syncManager.currentMode {
        case .localOnly:
            return .blue
        case .cloudSync:
            return .green
        case .taskPlusSync:
            return .purple
        }
    }
    
    private var appModeTitle: String {
        switch syncManager.currentMode {
        case .localOnly:
            return "ローカルモード"
        case .cloudSync:
            return "CloudKit同期モード"
        case .taskPlusSync:
            return "TaskPlus連携モード"
        }
    }
    
    private var appModeDescription: String {
        switch syncManager.currentMode {
        case .localOnly:
            return "Apple ID不要、基本的な機能のみ利用可能"
        case .cloudSync:
            return "iCloudアカウント必要、デバイス間同期"
        case .taskPlusSync:
            return "iCloudアカウント必要、TaskPlusとの完全同期連携"
        }
    }
    
    private var syncStatusIcon: String {
        switch syncManager.syncStatus {
        case .idle:
            return "circle"
        case .syncing:
            return "arrow.clockwise"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var syncStatusColor: Color {
        switch syncManager.syncStatus {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var syncStatusTitle: String {
        switch syncManager.syncStatus {
        case .idle:
            return "同期待機中"
        case .syncing:
            return "同期中"
        case .completed:
            return "同期完了"
        case .failed:
            return "同期失敗"
        }
    }
}

// MARK: - Import Sheet
struct ImportSheet: View {
    @Binding var importText: String
    let syncManager: TaskPlusSyncManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("TaskPlusからデータをインポート")
                .font(.headline)
                .padding(.top)
            
            Text("TaskPlusからエクスポートしたJSONデータを貼り付けてください")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextEditor(text: $importText)
                .frame(height: 200)
                .border(Color.gray.opacity(0.3), width: 1)
                .padding(.horizontal)
            
            Button("インポート実行") {
                Task {
                    do {
                        try await syncManager.importFromTaskPlus(importText)
                        alertMessage = "インポートが完了しました"
                        showingAlert = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            dismiss()
                        }
                    } catch {
                        alertMessage = "インポートエラー: \(error.localizedDescription)"
                        showingAlert = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(importText.isEmpty)
            
            Spacer()
        }
        .navigationTitle("データインポート")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("キャンセル") {
                    dismiss()
                }
            }
        }
        .alert("情報", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Export Sheet
struct ExportSheet: View {
    let syncManager: TaskPlusSyncManager
    @Environment(\.dismiss) private var dismiss
    @State private var exportText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("TaskPlus形式でデータをエクスポート")
                .font(.headline)
                .padding(.top)
            
            Text("以下のデータをコピーして、TaskPlusにインポートできます")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextEditor(text: .constant(exportText))
                .frame(height: 300)
                .border(Color.gray.opacity(0.3), width: 1)
                .padding(.horizontal)
                .onAppear {
                    exportText = syncManager.exportToTaskPlus() ?? "エクスポートできませんでした"
                }
            
            Button("コピー") {
                UIPasteboard.general.string = exportText
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .navigationTitle("データエクスポート")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完了") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    TaskPlusSyncView(syncManager: TaskPlusSyncManager(persistenceController: PersistenceController.shared))
}
