import Foundation
import SwiftUI

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

    init() {
        loadSettings()
        loadCompletedCount()
        loadCurrentTask()
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
        if hapticsEnabled {
            HapticsManager.shared.lightImpact()
        }
    }

    func pause() {
        state = .paused
        timer?.invalidate()
        timer = nil
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
        if hapticsEnabled {
            HapticsManager.shared.heavyImpact()
        }
    }

    func skip() {
        if phase == .focus {
            completeFocusSession()
        } else {
            completeBreakSession()
        }
        if hapticsEnabled {
            HapticsManager.shared.lightImpact()
        }
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
        phase = .break_
        timeRemaining = breakDuration * 60
        totalTime = timeRemaining
        state = .idle
        
        // 音の再生
        if soundEnabled {
            SoundManager.shared.playChime()
        }
    }

    private func completeBreakSession() {
        phase = .focus
        timeRemaining = focusDuration * 60
        totalTime = timeRemaining
        state = .idle
        
        // 音の再生
        if soundEnabled {
            SoundManager.shared.playChime()
        }
    }

    // MARK: - Task Management
    func setCurrentTask(_ task: TaskItem) {
        currentTaskName = task.name
        currentTaskEstimatedMinutes = task.estimatedMinutes
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
    
    // 選択された日付の時間ごとのポモドーロ完了数を取得
    func hourlyCompletedCounts(for date: Date) -> [Int] {
        let key = hourlyDateKey(for: date)
        let data = userDefaults.array(forKey: key) as? [Int] ?? Array(repeating: 0, count: 24)
        return data
    }
    
    // 今日の時間ごとのポモドーロ完了数を取得
    var hourlyCompletedCountsToday: [Int] {
        return hourlyCompletedCounts(for: Date())
    }
    
    // 選択された日付の時間ごとのポモドーロ完了数を取得
    var hourlyCompletedCountsForSelectedDate: [Int] {
        return hourlyCompletedCounts(for: selectedDate)
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
    }

    // MARK: - Private Methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timer?.invalidate()
                self.timer = nil
                self.state = .finished
                
                if self.phase == .focus {
                    self.completeFocusSession()
                } else {
                    self.completeBreakSession()
                }
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
    }
    
    private func resetHourlyCompletedCount() {
        let key = hourlyDateKey(for: Date())
        let emptyData = Array(repeating: 0, count: 24)
        userDefaults.set(emptyData, forKey: key)
    }

    private func loadCompletedCount() {
        let key = dateKey(for: Date())
        completedCountToday = userDefaults.integer(forKey: key)
    }

    private func saveCurrentTask() {
        userDefaults.set(currentTaskName, forKey: "currentTaskName")
        userDefaults.set(currentTaskEstimatedMinutes, forKey: "currentTaskEstimatedMinutes")
    }

    private func loadCurrentTask() {
        currentTaskName = userDefaults.string(forKey: "currentTaskName") ?? ""
        currentTaskEstimatedMinutes = userDefaults.integer(forKey: "currentTaskEstimatedMinutes")
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
}
