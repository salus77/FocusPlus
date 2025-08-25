//
//  FocusPlusWidget.swift
//  FocusPlusWidget
//
//  Created by Yasutaka Otsubo on 2025/08/24.
//

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
        
        // App Groupsからデータを取得
        let userDefaults = UserDefaults(suiteName: "group.com.delmar.FocusPlus")
        let completedCount = userDefaults?.integer(forKey: "completedCountToday") ?? 0
        let totalMinutes = completedCount * 25 // 25分 × 完了数
        
        // カテゴリ別統計を取得
        var categoryStats: [String: Int] = [:]
        if let data = userDefaults?.data(forKey: "categoryStatistics"),
           let stats = try? JSONDecoder().decode([String: Int].self, from: data) {
            categoryStats = stats
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

struct FocusPlusWidgetEntryView: View {
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
            Text("今日の完了")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(entry.completedCount)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("\(entry.totalMinutes)分")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        HStack(spacing: 16) {
            // 左側：基本統計
            VStack(spacing: 8) {
                Text("完了")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(entry.completedCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("\(entry.totalMinutes)分")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 右側：カテゴリ別統計
            VStack(alignment: .leading, spacing: 4) {
                Text("カテゴリ別")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(Array(entry.categoryStats.prefix(3)), id: \.key) { category, count in
                    HStack {
                        Text(category)
                            .font(.caption2)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(count)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct LargeWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            HStack {
                Text("FocusPlus")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(Date(), style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 基本統計
            HStack(spacing: 24) {
                VStack {
                    Text("完了数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(entry.completedCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                VStack {
                    Text("合計時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(entry.totalMinutes)分")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            
            // カテゴリ別統計
            VStack(alignment: .leading, spacing: 8) {
                Text("カテゴリ別完了数")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(Array(entry.categoryStats.sorted(by: { $0.value > $1.value })), id: \.key) { category, count in
                    HStack {
                        Text(category)
                            .font(.caption)
                        Spacer()
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct FocusPlusWidget: Widget {
    let kind: String = "FocusPlusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                FocusPlusWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                FocusPlusWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
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
            completedCount: 5,
            totalMinutes: 125,
            categoryStats: ["仕事": 3, "勉強": 2]
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        FocusPlusWidgetEntryView(entry: SimpleEntry(
            date: Date(),
            completedCount: 5,
            totalMinutes: 125,
            categoryStats: ["仕事": 3, "勉強": 2]
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        
        FocusPlusWidgetEntryView(entry: SimpleEntry(
            date: Date(),
            completedCount: 5,
            totalMinutes: 125,
            categoryStats: ["仕事": 3, "勉強": 2]
        ))
        .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
