import Foundation
import SwiftUI
import UserNotifications

enum TimerState {
    case idle
    case running
    case paused
    case finished
}

enum TimerPhase {
    case focus
    case break_
}

class TimerViewModel: ObservableObject {
    @Published var state: TimerState = .idle
    @Published var phase: TimerPhase = .focus
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var totalTime: TimeInterval = 25 * 60
    @Published var completedCountToday: Int = 0
    @Published var selectedDate: Date = Date()
    @Published var selectedCalendarMonth: Date = Date()
    @Published var currentTag: Tag?
    
    // Completion animation callback
    var onCompletionAnimationFinished: (() -> Void) = {}
    
    // Category statistics
    @Published var categoryStatistics: [String: Int] = [:]
    
    // Settings
    @Published var soundEnabled: Bool = true {
        didSet { saveSettings() }
    }
    @Published var hapticsEnabled: Bool = true {
        didSet { saveSettings() }
    }
    @Published var focusDuration: Double = 25 {
        didSet { 
            saveSettings()
            if state == .idle && phase == .focus {
                timeRemaining = focusDuration * 60
                totalTime = timeRemaining
            }
        }
    }
    @Published var breakDuration: Double = 5 {
        didSet { 
            saveSettings()
            if state == .idle && phase == .break_ {
                timeRemaining = breakDuration * 60
                totalTime = timeRemaining
            }
        }
    }
    @Published var isScreenAlwaysOn: Bool = false {
        didSet { 
            saveSettings()
            updateScreenState()
        }
    }
    
    @Published var isBackgroundRefreshEnabled: Bool = true {
        didSet { 
            saveSettings()
            updateBackgroundRefreshState()
        }
    }
    
    @Published var isBackgroundAudioEnabled: Bool = true {
        didSet { 
            saveSettings()
            updateBackgroundAudioState()
        }
    }
    


    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    private let widgetUserDefaults = UserDefaults(suiteName: "group.com.delmar.FocusPlus")

    init() {
        loadSettings()
        loadCompletedCount()
        updateWidgetData()
        // アプリ起動時にバッジをクリア
        clearBadge()
        
        // アプリのアクティブ状態を監視
        setupAppStateMonitoring()
    }
    
    // MARK: - Initialization
    /// 外部からの初期化完了通知（TagManagerの初期化完了後に呼び出される）
    func onInitializationComplete() {
        // 初期化完了後の処理
        print("🎯 TimerViewModel初期化完了")
        updateWidgetData()
    }
    
    // MARK: - App State Monitoring
    private func setupAppStateMonitoring() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearBadge()
            self?.startBadgeMonitoring()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearBadge()
            self?.startBadgeMonitoring()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stopBadgeMonitoring()
        }
    }
    
    private var badgeMonitoringTimer: Timer?
    
    private func startBadgeMonitoring() {
        // 既存のタイマーを停止
        stopBadgeMonitoring()
        
        // 1秒ごとにバッジをチェックしてクリア
        badgeMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.clearBadge()
        }
    }
    
    private func stopBadgeMonitoring() {
        badgeMonitoringTimer?.invalidate()
        badgeMonitoringTimer = nil
    }

    // MARK: - Timer Control
    func start() {
        guard state != .finished else { return }
        
        if state == .paused {
            state = .running
        } else {
            state = .running
            totalTime = timeRemaining
        }
        
        startTimer()
        updateWidgetData()
        if hapticsEnabled {
            HapticsManager.shared.lightImpact()
        }
    }

    func pause() {
        state = .paused
        timer?.invalidate()
        timer = nil
        updateWidgetData()
        updateScreenState() // スクリーン状態を更新
        if hapticsEnabled {
            HapticsManager.shared.lightImpact()
        }
    }

    func reset() {
        state = .idle
        timer?.invalidate()
        timer = nil
        timeRemaining = focusDuration * 60
        totalTime = timeRemaining
        updateWidgetData()
        updateScreenState() // スクリーン状態を更新
        if hapticsEnabled {
            HapticsManager.shared.heavyImpact()
        }
    }

    func skip() {
        // 現在のタイマーを停止
        timer?.invalidate()
        timer = nil
        
        if hapticsEnabled {
            HapticsManager.shared.lightImpact()
        }
        
        if phase == .focus {
            // フォーカスセッションを完了して、次のブレイクセッションをセット
            completedCountToday += 1
            saveCompletedCount()
            saveHourlyCompletedCount() // 時間ごとのデータを保存
            
            // 音の再生
            if soundEnabled {
                SoundManager.shared.playChime()
            }
            
            // 次のブレイクセッションをセットして停止状態にする
            phase = .break_
            timeRemaining = breakDuration * 60
            totalTime = timeRemaining
            state = .idle
        } else {
            // ブレイクセッションを完了して、次のフォーカスセッションをセット
            // 音の再生
            if soundEnabled {
                SoundManager.shared.playChime()
            }
            
            // 次のフォーカスセッションをセットして停止状態にする
            phase = .focus
            timeRemaining = focusDuration * 60
            totalTime = timeRemaining
            state = .idle
        }
        
        updateWidgetData()
        updateScreenState() // スクリーン状態を更新
    }

    // MARK: - Break Management
    func startBreak() {
        phase = .break_
        timeRemaining = breakDuration * 60
        totalTime = timeRemaining
        state = .idle
    }

    private func completeFocusSession() {
        print("🎯 completeFocusSession() 呼び出され")
        completedCountToday += 1
        saveCompletedCount()
        saveHourlyCompletedCount() // 時間ごとのデータを保存
        
        // 音の再生（即座に実行）
        print("🔊 音の再生を試行: soundEnabled=\(soundEnabled)")
        if soundEnabled {
            print("🔊 SoundManager.shared.playChime() を呼び出し")
            SoundManager.shared.playChime()
        } else {
            print("🔇 音が無効化されているため再生しません")
        }
        
        // 触覚フィードバック（振動）（即座に実行）
        print("📳 触覚フィードバックを試行: hapticsEnabled=\(hapticsEnabled)")
        if hapticsEnabled {
            print("📳 HapticsManager.shared.successNotification() を呼び出し")
            HapticsManager.shared.successNotification()
        } else {
            print("📳 触覚フィードバックが無効化されているため実行しません")
        }
        
        // 通知の送信
        let taskName = currentTag?.name ?? "集中セッション"
        sendNotification(
            title: "集中セッション完了！",
            body: "\(taskName)が完了しました。お疲れ様でした！"
        )
        
        // 点滅アニメーション完了後の処理は、CircularDialViewからコールバックされる
    }

    private func completeBreakSession() {
        print("🎯 completeBreakSession() 呼び出され")
        
        // 音の再生（即座に実行）
        print("🔊 音の再生を試行: soundEnabled=\(soundEnabled)")
        if soundEnabled {
            print("🔊 SoundManager.shared.playChime() を呼び出し")
            SoundManager.shared.playChime()
        } else {
            print("🔇 音が無効化されているため再生しません")
        }
        
        // 触覚フィードバック（振動）（即座に実行）
        print("📳 触覚フィードバックを試行: hapticsEnabled=\(hapticsEnabled)")
        if hapticsEnabled {
            print("📳 HapticsManager.shared.successNotification() を呼び出し")
            HapticsManager.shared.successNotification()
        } else {
            print("📳 触覚フィードバックが無効化されているため実行しません")
        }
        
        // 通知の送信
        sendNotification(
            title: "休憩時間完了",
            body: "休憩が終わりました。次の集中セッションを始めましょう！"
        )
        
        // 点滅アニメーション完了後の処理は、CircularDialViewからコールバックされる
    }
    
    // MARK: - Animation Completion Callback
    /// 点滅アニメーション完了後の処理
    func handleCompletionAnimationFinished() {
        print("🎬 点滅アニメーション完了: 状態をリセット")
        
        if phase == .focus {
            // 集中セッション完了後の処理
            phase = .break_
            timeRemaining = breakDuration * 60
            totalTime = timeRemaining
            state = .idle
            updateWidgetData()
        } else {
            // 休憩時間完了後の処理
            phase = .focus
            timeRemaining = focusDuration * 60
            totalTime = timeRemaining
            state = .idle
            updateWidgetData()
        }
    }

    // MARK: - Tag Management
    func setCurrentTask(name: String, estimatedMinutes: Int, categoryColor: Color) {
        // このメソッドは後方互換性のために残していますが、実際には使用されません
        // 新しいタグ管理システムでは currentTag を使用します
    }

    // MARK: - Statistics
    var completedCountForSelectedDate: Int {
        let key = dateKey(for: selectedDate)
        return userDefaults.integer(forKey: key)
    }

    var completedCountForSelectedMonth: Int {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: selectedCalendarMonth)?.start ?? selectedCalendarMonth
        let monthEnd = calendar.dateInterval(of: .month, for: selectedCalendarMonth)?.end ?? selectedCalendarMonth

        var total = 0
        var currentDate = monthStart

        while currentDate < monthEnd {
            let key = dateKey(for: currentDate)
            total += userDefaults.integer(forKey: key)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return total
    }
    
    // 全体のカテゴリ別統計を取得
    func getOverallCategoryStatistics() -> [String: Int] {
        var overallStats: [String: Int] = [:]
        
        // 過去1年分のデータを集計
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        var currentDate = oneYearAgo
        
        while currentDate <= Date() {
            let key = categoryStatisticsKey(for: currentDate)
            if let data = userDefaults.data(forKey: key),
               let statistics = try? JSONDecoder().decode([String: Int].self, from: data) {
                for (category, count) in statistics {
                    overallStats[category, default: 0] += count
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return overallStats
    }
    
    // 選択された月のカテゴリ別統計を取得
    func getMonthlyCategoryStatistics() -> [String: Int] {
        var monthlyStats: [String: Int] = [:]
        
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: selectedCalendarMonth)?.start ?? selectedCalendarMonth
        let monthEnd = calendar.dateInterval(of: .month, for: selectedCalendarMonth)?.end ?? selectedCalendarMonth
        var currentDate = monthStart
        
        while currentDate < monthEnd {
            let key = categoryStatisticsKey(for: currentDate)
            if let data = userDefaults.data(forKey: key),
               let statistics = try? JSONDecoder().decode([String: Int].self, from: data) {
                for (category, count) in statistics {
                    monthlyStats[category, default: 0] += count
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return monthlyStats
    }
    
    // カテゴリ別統計をソートして上位N件を取得
    func getTopCategories(from statistics: [String: Int], limit: Int = 5) -> [(category: String, count: Int)] {
        return statistics.sorted { $0.value > $1.value }.prefix(limit).map { ($0.key, $0.value) }
    }
    
    // カテゴリ別統計の合計を取得
    func getTotalCount(from statistics: [String: Int]) -> Int {
        return statistics.values.reduce(0, +)
    }
    
    // 選択された日付の時間ごとのポモドーロ完了数を取得
    func hourlyCompletedCounts(for date: Date) -> [Int] {
        let key = hourlyDateKey(for: date)
        let data = userDefaults.array(forKey: key) as? [Int] ?? Array(repeating: 0, count: 24)
        return data
    }
    
    // 選択された日付の時間ごとの完了色情報を取得
    func hourlyCompletedColors(for date: Date) -> [Color] {
        let key = hourlyColorKey(for: date)
        let colorData = userDefaults.array(forKey: key) as? [[CGFloat]] ?? Array(repeating: [], count: 24)
        
        return colorData.map { components in
            if components.count >= 3 {
                return Color(.sRGB, 
                           red: components[0], 
                           green: components[1], 
                           blue: components[2], 
                           opacity: components.count > 3 ? components[3] : 1.0)
            } else {
                return DesignSystem.Colors.neonBlue // デフォルト色
            }
        }
    }
    
    // 今日の時間ごとのポモドーロ完了数を取得
    var hourlyCompletedCountsToday: [Int] {
        return hourlyCompletedCounts(for: Date())
    }
    
    // 選択された日付の時間ごとのポモドーロ完了数を取得
    var hourlyCompletedCountsForSelectedDate: [Int] {
        return hourlyCompletedCounts(for: selectedDate)
    }
    
    // 選択された日付の時間ごとの完了色情報を取得
    var hourlyColorsForSelectedDate: [Color] {
        return hourlyCompletedColors(for: selectedDate)
    }
    
    // 今日の時間ごとの完了色情報を取得
    var hourlyColorsForToday: [Color] {
        return hourlyCompletedColors(for: Date())
    }
    
    // 指定された日付の完了数を取得
    func completedCounts(for date: Date) -> Int {
        let key = dateKey(for: date)
        return userDefaults.integer(forKey: key)
    }

    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func selectCalendarMonth(_ date: Date) {
        selectedCalendarMonth = date
    }
    
    /// 統計画面を開くときに現在の日時を選択状態にする
    func resetSelectedDateToToday() {
        selectedDate = Date()
    }

    func resetCompletedCount() {
        completedCountToday = 0
        saveCompletedCount()
        resetHourlyCompletedCount() // 時間ごとのデータもリセット
        resetHourlyCompletedColors() // 色情報もリセット
    }

    // MARK: - Private Methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                self.updateWidgetData()
            } else {
                self.timer?.invalidate()
                self.timer = nil
                
                // タイマー完了時に.finished状態を設定
                self.state = .finished
                
                // 点滅アニメーションのための遅延処理
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    
                    if self.phase == .focus {
                        self.completeFocusSession()
                    } else {
                        self.completeBreakSession()
                    }
                }
            }
        }
    }
    
    private func updateWidgetData() {
        widgetUserDefaults?.set(completedCountToday, forKey: "completedCountToday")
        widgetUserDefaults?.set(state == .running, forKey: "isTimerRunning")
        widgetUserDefaults?.set(Int(timeRemaining), forKey: "timeRemaining")
        
        // カテゴリ別統計をウィジットと共有
        if let categoryData = try? JSONEncoder().encode(categoryStatistics) {
            widgetUserDefaults?.set(categoryData, forKey: "categoryStatistics")
        }
        
        // 時間別完了数も共有
        let now = Date()
        let key = hourlyDateKey(for: now)
        if let hourlyData = userDefaults.array(forKey: key) as? [Int] {
            if let hourlyDataEncoded = try? JSONEncoder().encode(hourlyData) {
                widgetUserDefaults?.set(hourlyDataEncoded, forKey: "hourlyCompletedCounts")
            }
        }
    }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "completedCount_\(formatter.string(from: date))"
    }
    
    private func hourlyDateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "hourlyCompletedCount_\(formatter.string(from: date))"
    }

    private func saveCompletedCount() {
        let key = dateKey(for: Date())
        userDefaults.set(completedCountToday, forKey: key)
    }
    
    private func saveHourlyCompletedCount() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        let key = hourlyDateKey(for: now)
        var hourlyData = userDefaults.array(forKey: key) as? [Int] ?? Array(repeating: 0, count: 24)
        hourlyData[hour] += 1
        userDefaults.set(hourlyData, forKey: key)
        
        // 色情報も保存
        saveHourlyCompletedColor(hour: hour)
        
        // カテゴリ統計も更新
        if let tag = currentTag {
            // タグ名をカテゴリとして使用
            let categoryName = tag.name
            updateCategoryStatistics(categoryName: categoryName)
        }
    }
    
    private func saveHourlyCompletedColor(hour: Int) {
        let now = Date()
        let key = hourlyColorKey(for: now)
        var hourlyColors = userDefaults.array(forKey: key) as? [[CGFloat]] ?? Array(repeating: [], count: 24)
        
        // 現在のタスクのカテゴリ色をRGB値で保存
        let colorComponents = UIColor(currentTag?.color ?? DesignSystem.Colors.neonBlue).cgColor.components ?? [0, 0.7, 1, 1]
        hourlyColors[hour] = Array(colorComponents)
        userDefaults.set(hourlyColors, forKey: key)
    }
    
    private func hourlyColorKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "hourlyCompletedColor_\(formatter.string(from: date))"
    }
    
    private func resetHourlyCompletedCount() {
        let key = hourlyDateKey(for: Date())
        let emptyData = Array(repeating: 0, count: 24)
        userDefaults.set(emptyData, forKey: key)
    }

    private func resetHourlyCompletedColors() {
        let key = hourlyColorKey(for: Date())
        let emptyColors = Array(repeating: [], count: 24)
        userDefaults.set(emptyColors, forKey: key)
    }

    private func loadCompletedCount() {
        let key = dateKey(for: Date())
        completedCountToday = userDefaults.integer(forKey: key)
    }

    private func saveCurrentTask() {
        // 新しいタグ管理システムでは使用されません
    }

    private func loadCurrentTask() {
        // 新しいタグ管理システムでは使用されません
        // カテゴリ別統計データを読み込み
        loadCategoryStatistics()
    }
    
    // MARK: - Settings Management
    private func saveSettings() {
        userDefaults.set(soundEnabled, forKey: "soundEnabled")
        userDefaults.set(hapticsEnabled, forKey: "hapticsEnabled")
        userDefaults.set(focusDuration, forKey: "focusDuration")
        userDefaults.set(breakDuration, forKey: "breakDuration")
        userDefaults.set(isScreenAlwaysOn, forKey: "isScreenAlwaysOn")
        userDefaults.set(isBackgroundRefreshEnabled, forKey: "isBackgroundRefreshEnabled")
        userDefaults.set(isBackgroundAudioEnabled, forKey: "isBackgroundAudioEnabled")
    }
    
    private func loadSettings() {
        soundEnabled = userDefaults.object(forKey: "soundEnabled") as? Bool ?? true
        hapticsEnabled = userDefaults.object(forKey: "hapticsEnabled") as? Bool ?? true
        focusDuration = userDefaults.object(forKey: "focusDuration") as? Double ?? 25
        breakDuration = userDefaults.object(forKey: "breakDuration") as? Double ?? 5
        isScreenAlwaysOn = userDefaults.object(forKey: "isScreenAlwaysOn") as? Bool ?? false
        isBackgroundRefreshEnabled = userDefaults.object(forKey: "isBackgroundRefreshEnabled") as? Bool ?? true
        isBackgroundAudioEnabled = userDefaults.object(forKey: "isBackgroundAudioEnabled") as? Bool ?? true
        
        // 初期時間の設定
        if state == .idle {
            if phase == .focus {
                timeRemaining = focusDuration * 60
                totalTime = timeRemaining
            } else {
                timeRemaining = breakDuration * 60
                totalTime = timeRemaining
            }
        }
    }
    
    // MARK: - Category Statistics Management
    private func loadCategoryStatistics() {
        let key = categoryStatisticsKey(for: Date())
        if let data = userDefaults.data(forKey: key),
           let statistics = try? JSONDecoder().decode([String: Int].self, from: data) {
            categoryStatistics = statistics
        } else {
            categoryStatistics = [:]
        }
    }
    
    private func saveCategoryStatistics() {
        let key = categoryStatisticsKey(for: Date())
        if let data = try? JSONEncoder().encode(categoryStatistics) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    private func categoryStatisticsKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "categoryStatistics_\(formatter.string(from: date))"
    }
    
    func updateCategoryStatistics(categoryName: String) {
        categoryStatistics[categoryName, default: 0] += 1
        saveCategoryStatistics()
    }
    
    // MARK: - Tag Color Management
    func updateCurrentTaskCategoryColor(_ color: Color) {
        // 新しいタグ管理システムでは使用されません
    }
    
    func getCategoryColor(for categoryName: String) -> Color {
        // カテゴリ名に対応する色を返す
        // 既存のカテゴリの場合はその色を、新規の場合はデフォルト色を返す
        switch categoryName.lowercased() {
        case "仕事", "work":
            return .blue
        case "勉強", "study":
            return .green
        case "運動", "exercise", "fitness":
            return .orange
        case "趣味", "hobby":
            return .purple
        case "家事", "housework":
            return .pink
        case "読書", "reading":
            return .mint
        case "音楽", "music":
            return .teal
        case "料理", "cooking":
            return .brown
        default:
            return DesignSystem.Colors.neonBlue
        }
    }
    
    func getCategoryStatistics(for date: Date) -> [String: Int] {
        let key = categoryStatisticsKey(for: date)
        if let data = userDefaults.data(forKey: key),
           let statistics = try? JSONDecoder().decode([String: Int].self, from: data) {
            return statistics
        }
        return [:]
    }
    

    
    // MARK: - Notification Management
    private func sendNotification(title: String, body: String, categoryIdentifier: String = "FOCUSPLUS_TIMER") {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.badge = NSNumber(value: 1) // バッジ数を1に設定
        
        // 即座に通知を送信
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知の送信でエラーが発生しました: \(error.localizedDescription)")
            } else {
                print("通知が正常に送信されました")
                // バッジ数を1に設定
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = 1
                }
            }
        }
    }

    // MARK: - Badge Management
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    // MARK: - Screen State Management
    private func updateScreenState() {
        // タイマー実行中かつスクリーン常時オンが有効な場合のみ、画面を常時オンにする
        if isScreenAlwaysOn && (state == .running) {
            UIApplication.shared.isIdleTimerDisabled = true
        } else {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    // MARK: - Background Refresh Management
    private func updateBackgroundRefreshState() {
        // バックグラウンド更新の設定をシステムに反映
        // 実際の実装では、システムのバックグラウンド更新設定と連携
        print("バックグラウンド更新設定が変更されました: \(isBackgroundRefreshEnabled)")
    }
    
    // MARK: - Background Audio Management
    private func updateBackgroundAudioState() {
        // バックグラウンド音声再生の設定をシステムに反映
        // 実際の実装では、AVAudioSessionの設定と連携
        print("バックグラウンド音声再生設定が変更されました: \(isBackgroundAudioEnabled)")
    }
    
    // MARK: - Cleanup
    deinit {
        stopBadgeMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
}
