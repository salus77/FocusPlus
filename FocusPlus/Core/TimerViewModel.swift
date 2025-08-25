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
    @Published var currentTaskName: String = ""
    @Published var currentTaskEstimatedMinutes: Int = 0
    @Published var currentTaskCategoryColor: Color = DesignSystem.Colors.neonBlue
    
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

    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    private let widgetUserDefaults = UserDefaults(suiteName: "group.com.delmar.FocusPlus")

    init() {
        loadSettings()
        loadCompletedCount()
        loadCurrentTask()
        updateWidgetData()
        // アプリ起動時にバッジをクリア
        clearBadge()
        
        // アプリのアクティブ状態を監視
        setupAppStateMonitoring()
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
    }

    // MARK: - Break Management
    func startBreak() {
        phase = .break_
        timeRemaining = breakDuration * 60
        totalTime = timeRemaining
        state = .idle
    }

    private func completeFocusSession() {
        completedCountToday += 1
        saveCompletedCount()
        saveHourlyCompletedCount() // 時間ごとのデータを保存
        
        // 音の再生
        if soundEnabled {
            SoundManager.shared.playChime()
        }
        
        // 通知の送信
        let taskName = currentTaskName.isEmpty ? "集中セッション" : currentTaskName
        sendNotification(
            title: "集中セッション完了！",
            body: "\(taskName)が完了しました。お疲れ様でした！"
        )
        
        // 点滅アニメーション完了後に状態をリセット
        // この処理はCircularDialViewのアニメーション完了後に実行される
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.phase = .break_
            self.timeRemaining = self.breakDuration * 60
            self.totalTime = self.timeRemaining
            self.state = .idle
            self.updateWidgetData()
        }
    }

    private func completeBreakSession() {
        // 音の再生
        if soundEnabled {
            SoundManager.shared.playChime()
        }
        
        // 通知の送信
        sendNotification(
            title: "休憩時間完了",
            body: "休憩が終わりました。次の集中セッションを始めましょう！"
        )
        
        // 点滅アニメーション完了後に状態をリセット
        // この処理はCircularDialViewのアニメーション完了後に実行される
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.phase = .focus
            self.timeRemaining = self.focusDuration * 60
            self.totalTime = self.timeRemaining
            self.state = .idle
            self.updateWidgetData()
        }
    }

    // MARK: - Task Management
    func setCurrentTask(name: String, estimatedMinutes: Int, categoryColor: Color) {
        currentTaskName = name
        currentTaskEstimatedMinutes = estimatedMinutes
        currentTaskCategoryColor = categoryColor
        saveCurrentTask()
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
        if !currentTaskName.isEmpty {
            // タスク名からカテゴリ名を抽出（例：タスク名が "Work: プロジェクトA" の場合、"Work" がカテゴリ）
            let categoryName = extractCategoryFromTaskName(currentTaskName)
            updateCategoryStatistics(categoryName: categoryName)
        }
    }
    
    private func saveHourlyCompletedColor(hour: Int) {
        let now = Date()
        let key = hourlyColorKey(for: now)
        var hourlyColors = userDefaults.array(forKey: key) as? [[CGFloat]] ?? Array(repeating: [], count: 24)
        
        // 現在のタスクのカテゴリ色をRGB値で保存
        let colorComponents = UIColor(currentTaskCategoryColor).cgColor.components ?? [0, 0.7, 1, 1]
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
        userDefaults.set(currentTaskName, forKey: "currentTaskName")
        userDefaults.set(currentTaskEstimatedMinutes, forKey: "currentTaskEstimatedMinutes")
        
        // カテゴリの色をRGB値で保存
        let colorComponents = UIColor(currentTaskCategoryColor).cgColor.components ?? [0, 0.7, 1, 1] // デフォルトはneonBlue
        userDefaults.set(Array(colorComponents), forKey: "currentTaskCategoryColor")
    }

    private func loadCurrentTask() {
        currentTaskName = userDefaults.string(forKey: "currentTaskName") ?? ""
        currentTaskEstimatedMinutes = userDefaults.integer(forKey: "currentTaskEstimatedMinutes")
        
        // カテゴリの色を復元
        if let colorComponents = userDefaults.array(forKey: "currentTaskCategoryColor") as? [CGFloat],
           colorComponents.count >= 3 {
            currentTaskCategoryColor = Color(.sRGB, 
                                           red: colorComponents[0], 
                                           green: colorComponents[1], 
                                           blue: colorComponents[2], 
                                           opacity: colorComponents.count > 3 ? colorComponents[3] : 1.0)
        } else {
            currentTaskCategoryColor = DesignSystem.Colors.neonBlue
        }
        
        // カテゴリ別統計データを読み込み
        loadCategoryStatistics()
    }
    
    // MARK: - Settings Management
    private func saveSettings() {
        userDefaults.set(soundEnabled, forKey: "soundEnabled")
        userDefaults.set(hapticsEnabled, forKey: "hapticsEnabled")
        userDefaults.set(focusDuration, forKey: "focusDuration")
        userDefaults.set(breakDuration, forKey: "breakDuration")
    }
    
    private func loadSettings() {
        soundEnabled = userDefaults.object(forKey: "soundEnabled") as? Bool ?? true
        hapticsEnabled = userDefaults.object(forKey: "hapticsEnabled") as? Bool ?? true
        focusDuration = userDefaults.object(forKey: "focusDuration") as? Double ?? 25
        breakDuration = userDefaults.object(forKey: "breakDuration") as? Double ?? 5
        
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
    
    // MARK: - Category Color Management
    func updateCurrentTaskCategoryColor(_ color: Color) {
        currentTaskCategoryColor = color
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
    
    private func extractCategoryFromTaskName(_ taskName: String) -> String {
        // タスク名からカテゴリ名を抽出
        // 例: "Work: プロジェクトA" -> "Work"
        if let colonIndex = taskName.firstIndex(of: ":") {
            return String(taskName[..<colonIndex]).trimmingCharacters(in: .whitespaces)
        }
        // コロンがない場合は、タスク名をそのままカテゴリとして使用
        return taskName
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
    
    // MARK: - Cleanup
    deinit {
        stopBadgeMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
}
