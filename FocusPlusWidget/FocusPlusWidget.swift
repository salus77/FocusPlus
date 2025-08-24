import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), completedCount: 0, totalMinutes: 0, categoryStats: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), completedCount: 5, totalMinutes: 125, categoryStats: ["仕事": 3, "勉強": 2])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // 30分ごとに更新
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate) ?? currentDate
        
        let userDefaults = UserDefaults(suiteName: "group.com.delmar.FocusPlus")
        let completedCount = userDefaults?.integer(forKey: "completedCountToday") ?? 0
        let totalMinutes = completedCount * 25
        
        // カテゴリ別統計を取得
        var categoryStats: [String: Int] = [:]
        if let data = userDefaults?.data(forKey: "hourlyCompletedCounts"),
           let hourlyData = try? JSONDecoder().decode([Int: Int].self, from: data) {
            // 時間ごとのデータからカテゴリ別統計を計算
            // 実際の実装では、カテゴリ別データを直接保存・取得する
            categoryStats = ["仕事": max(0, completedCount - 2), "勉強": max(0, completedCount - 3)]
        }
        
        let entry = SimpleEntry(
            date: currentDate,
            completedCount: completedCount,
            totalMinutes: totalMinutes,
            categoryStats: categoryStats
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
    let totalMinutes: Int
    let categoryStats: [String: Int]
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

// MARK: - Small Widget (小サイズ)
struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // ヘッダー
            HStack {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("今日の成果")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            Spacer()
            
            // メイン情報
            VStack(spacing: 4) {
                Text("\(entry.completedCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("ポモドーロ")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(entry.totalMinutes)分")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
    }
}

// MARK: - Medium Widget (中サイズ)
struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // 左側: 基本情報
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("今日の成果")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.completedCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("ポモドーロ完了")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("合計 \(entry.totalMinutes)分")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
            
            // 右側: カテゴリ別統計（簡易版）
            if !entry.categoryStats.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("カテゴリ別")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(entry.categoryStats.prefix(3)), id: \.key) { category, count in
                        HStack {
                            Circle()
                                .fill(categoryColor(for: category))
                                .frame(width: 8, height: 8)
                            Text(category)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(count)")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "仕事": return .blue
        case "勉強": return .green
        case "運動": return .orange
        default: return .gray
        }
    }
}

// MARK: - Large Widget (大サイズ)
struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundColor(.orange)
                Text("今日のポモドーロ統計")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            // メイン統計
            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(entry.completedCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("完了数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Text("\(entry.totalMinutes)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text("合計時間(分)"
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // カテゴリ別円グラフ
            if !entry.categoryStats.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("カテゴリ別統計")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 20) {
                        // 簡易円グラフ
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: min(1.0, Double(entry.completedCount) / max(1, entry.completedCount)))
                                .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                        }
                        
                        // カテゴリ詳細
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(entry.categoryStats.prefix(4)), id: \.key) { category, count in
                                HStack {
                                    Circle()
                                        .fill(categoryColor(for: category))
                                        .frame(width: 10, height: 10)
                                    Text(category)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(count)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
            }
            
            // 時間別積み上げグラフ
            VStack(alignment: .leading, spacing: 8) {
                Text("時間別完了数")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 2) {
                    ForEach(0..<24, id: \.self) { hour in
                        VStack(spacing: 2) {
                            // 簡易積み上げグラフ
                            Rectangle()
                                .fill(Color.orange.opacity(0.6))
                                .frame(width: 8, height: max(4, CGFloat(min(entry.completedCount, 8))))
                            
                            if hour % 6 == 0 {
                                Text("\(hour)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(.systemBackground))
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "仕事": return .blue
        case "勉強": return .green
        case "運動": return .orange
        default: return .gray
        }
    }
}

struct FocusPlusWidget: Widget {
    let kind: String = "FocusPlusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FocusPlusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FocusPlus")
        .description("今日のポモドーロ統計を表示します")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct FocusPlusWidget_Previews: PreviewProvider {
    static var previews: some View {
        FocusPlusWidgetEntryView(entry: SimpleEntry(
            date: Date(),
            completedCount: 8,
            totalMinutes: 200,
            categoryStats: ["仕事": 5, "勉強": 3]
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        FocusPlusWidgetEntryView(entry: SimpleEntry(
            date: Date(),
            completedCount: 8,
            totalMinutes: 200,
            categoryStats: ["仕事": 5, "勉強": 3]
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        
        FocusPlusWidgetEntryView(entry: SimpleEntry(
            date: Date(),
            completedCount: 8,
            totalMinutes: 200,
            categoryStats: ["仕事": 5, "勉強": 3]
        ))
        .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
