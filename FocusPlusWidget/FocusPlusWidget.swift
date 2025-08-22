import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), completedCount: 0, isTimerRunning: false, timeRemaining: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), completedCount: 0, isTimerRunning: false, timeRemaining: 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // 現在の時間から1時間後まで、5分間隔でエントリを作成
        let currentDate = Date()
        for minuteOffset in 0 ..< 12 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset * 5, to: currentDate)!
            let entry = SimpleEntry(
                date: entryDate,
                completedCount: getCompletedCount(),
                isTimerRunning: isTimerRunning(),
                timeRemaining: getTimeRemaining()
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func getCompletedCount() -> Int {
        let userDefaults = UserDefaults(suiteName: "group.com.delmar.FocusPlus")
        return userDefaults?.integer(forKey: "completedCountToday") ?? 0
    }
    
    private func isTimerRunning() -> Bool {
        let userDefaults = UserDefaults(suiteName: "group.com.delmar.FocusPlus")
        return userDefaults?.bool(forKey: "isTimerRunning") ?? false
    }
    
    private func getTimeRemaining() -> Int {
        let userDefaults = UserDefaults(suiteName: "group.com.delmar.FocusPlus")
        return userDefaults?.integer(forKey: "timeRemaining") ?? 0
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
    let isTimerRunning: Bool
    let timeRemaining: Int
}

struct FocusPlusWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 8) {
            // アイコン
            Image(systemName: "timer")
                .font(.title2)
                .foregroundColor(.white)
            
            // 完了数
            Text("\(entry.completedCount)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("ポモドーロ")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            // タイマー状態
            if entry.isTimerRunning {
                Text(formatTime(entry.timeRemaining))
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        HStack(spacing: 16) {
            // 左側: 完了数
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                
                Text("\(entry.completedCount)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("完了")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // 右側: タイマー状態
            VStack(spacing: 8) {
                if entry.isTimerRunning {
                    Image(systemName: "timer")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Text(formatTime(entry.timeRemaining))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("残り時間")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Image(systemName: "play.circle")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("開始")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct LargeWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: "timer")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("FocusPlus")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(Date(), style: .time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // メインコンテンツ
            HStack(spacing: 20) {
                // 完了数
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text("\(entry.completedCount)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("ポモドーロ完了")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                
                // タイマー状態
                VStack(spacing: 12) {
                    if entry.isTimerRunning {
                        Image(systemName: "timer")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text(formatTime(entry.timeRemaining))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("残り時間")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Image(systemName: "play.circle")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        Text("タイマー開始")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            // フッター
            HStack {
                Text("今日の進捗")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

@main
struct FocusPlusWidget: Widget {
    let kind: String = "FocusPlusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FocusPlusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FocusPlus")
        .description("ポモドーロタイマーの進捗と状態を表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct FocusPlusWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FocusPlusWidgetEntryView(entry: SimpleEntry(date: Date(), completedCount: 5, isTimerRunning: true, timeRemaining: 1200))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget")
            
            FocusPlusWidgetEntryView(entry: SimpleEntry(date: Date(), completedCount: 5, isTimerRunning: true, timeRemaining: 1200))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Widget")
            
            FocusPlusWidgetEntryView(entry: SimpleEntry(date: Date(), completedCount: 5, isTimerRunning: true, timeRemaining: 1200))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large Widget")
        }
    }
}
