import SwiftUI

struct StatisticsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Calendar Section
                VStack(spacing: 16) {
                    Text("カレンダー")
                        .subheadlineStyle()
                        .secondaryText()
                    
                    CalendarView(viewModel: viewModel)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Hourly Pomodoro Graph
                HourlyPomodoroGraphView(
                    hourlyData: viewModel.hourlyCompletedCountsForSelectedDate,
                    hourlyColors: viewModel.hourlyColorsForSelectedDate,
                    selectedDate: viewModel.selectedDate
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Selected Date Statistics
                StatCard(
                    title: "統計情報",
                    icon: "calendar.badge.clock",
                    items: [
                        StatItem(label: "完了数", value: "\(viewModel.completedCountForSelectedDate)回"),
                        StatItem(label: "集中時間", value: "\(viewModel.completedCountForSelectedDate * 25)分")
                    ]
                )
                
                // Monthly Statistics
                StatCard(
                    title: "月間統計",
                    icon: "calendar.badge.plus",
                    items: [
                        StatItem(label: "完了数", value: "\(viewModel.completedCountForSelectedMonth)回"),
                        StatItem(label: "集中時間", value: "\(viewModel.completedCountForSelectedMonth * 25)分")
                    ]
                )
                
                // Monthly Category Statistics
                CategoryStatisticsCard(
                    title: "月間カテゴリ別統計",
                    icon: "chart.pie.fill",
                    statistics: viewModel.getMonthlyCategoryStatistics(),
                    totalCount: viewModel.getTotalCount(from: viewModel.getMonthlyCategoryStatistics())
                )
                
                // Overall Category Statistics
                CategoryStatisticsCard(
                    title: "全体カテゴリ別統計",
                    icon: "chart.bar.fill",
                    statistics: viewModel.getOverallCategoryStatistics(),
                    totalCount: viewModel.getTotalCount(from: viewModel.getOverallCategoryStatistics())
                )
                
                // Current Task
                if !viewModel.currentTaskName.isEmpty {
                    StatCard(
                        title: "現在のタスク",
                        icon: "checkmark.circle.fill",
                        items: [
                            StatItem(label: "タスク名", value: viewModel.currentTaskName),
                            StatItem(label: "推定時間", value: "\(viewModel.currentTaskEstimatedMinutes)分")
                        ]
                    )
                }
                
                // Reset Button
                Button(action: {
                    viewModel.resetCompletedCount()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                        
                        Text("完了数をリセット")
                            .headlineStyle()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(DesignSystem.Colors.warning)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("統計")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // 統計画面が表示されるときに現在の日時を選択状態にする
            viewModel.resetSelectedDateToToday()
        }
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(DesignSystem.Colors.neonBlue)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .headlineStyle()
                    .primaryText()
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(DesignSystem.Colors.neonBlue)
                }
            }
            
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                    Text(day)
                        .captionStyle()
                        .secondaryText()
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                            completedCount: viewModel.completedCounts(for: date)
                        )
                        .onTapGesture {
                            viewModel.selectDate(date)
                        }
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
        }
        .onAppear {
            // カレンダーが表示されるときに現在の月を表示
            currentMonth = viewModel.selectedDate
        }
        .onChange(of: viewModel.selectedDate) { _, newDate in
            // 選択日が変更されたときにカレンダーの月も同期
            currentMonth = newDate
        }
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func daysInMonth() -> [Date?] {
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstDate = interval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstDate)
        let offsetDays = firstWeekday - 1
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDate) {
                days.append(date)
            }
        }
        
        // 7の倍数になるように調整
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let completedCount: Int
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 2) {
            Text(dateFormatter.string(from: date))
                .captionStyle()
                .foregroundColor(isSelected ? .black : .white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? DesignSystem.Colors.neonBlue : Color.clear)
                )
            
            if completedCount > 0 {
                HStack(spacing: 1) {
                    ForEach(0..<min(completedCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(DesignSystem.Colors.neonBlue)
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
    }
}

// MARK: - Hourly Pomodoro Graph View
struct HourlyPomodoroGraphView: View {
    let hourlyData: [Int]
    let hourlyColors: [Color]
    let selectedDate: Date
    
    private let timeLabels = ["0:00", "6:00", "12:00", "18:00"]
    private let maxValue: Int
    
    init(hourlyData: [Int], hourlyColors: [Color], selectedDate: Date) {
        self.hourlyData = hourlyData
        self.hourlyColors = hourlyColors
        self.selectedDate = selectedDate
        self.maxValue = max(hourlyData.max() ?? 1, 1)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Graph
            ZStack {
                // Background Grid Lines
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        if index < 2 {
                            Spacer()
                        }
                    }
                }
                
                // Dots Stack
                HStack(alignment: .bottom, spacing: 1) {
                    ForEach(0..<24, id: \.self) { hour in
                        VStack(spacing: 2) {
                            Spacer()
                            
                            // ポモドーロ数分のドットを積み上げ
                            VStack(spacing: 1) {
                                ForEach(0..<hourlyData[hour], id: \.self) { dotIndex in
                                    Circle()
                                        .fill(hourlyColors[hour])
                                        .frame(width: 6, height: 6)
                                        .shadow(
                                            color: hourlyColors[hour].opacity(0.6),
                                            radius: 1,
                                            x: 0,
                                            y: 0
                                        )
                                }
                            }
                        }
                        .frame(width: 8) // 各時間の幅を統一
                    }
                }
            }
            .frame(height: 80)
            
            // Time Labels
            HStack {
                ForEach(timeLabels, id: \.self) { label in
                    Text(label)
                        .captionStyle()
                        .foregroundColor(.white)
                    
                    if label != timeLabels.last {
                        Spacer()
                    }
                }
            }
        }
    }
}



// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let icon: String
    let items: [StatItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(DesignSystem.Colors.neonBlue)
                
                Text(title)
                    .headlineStyle()
                    .primaryText()
            }
            
            VStack(spacing: 12) {
                ForEach(items, id: \.label) { item in
                    HStack {
                        Text(item.label)
                            .bodyStyle()
                            .secondaryText()
                        
                        Spacer()
                        
                        Text(item.value)
                            .headlineStyle()
                            .primaryText()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Stat Item
struct StatItem {
    let label: String
    let value: String
}

// MARK: - Category Statistics Card
struct CategoryStatisticsCard: View {
    let title: String
    let icon: String
    let statistics: [String: Int]
    let totalCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(DesignSystem.Colors.neonBlue)
                
                Text(title)
                    .subheadlineStyle()
                    .secondaryText()
                
                Spacer()
                
                Text("合計: \(totalCount)回")
                    .captionStyle()
                    .secondaryText()
            }
            
            if statistics.isEmpty {
                Text("データがありません")
                    .captionStyle()
                    .secondaryText()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(statistics.sorted { $0.value > $1.value }.prefix(5)), id: \.key) { category, count in
                        CategoryStatRow(
                            category: category,
                            count: count,
                            percentage: totalCount > 0 ? Double(count) / Double(totalCount) * 100 : 0
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Category Stat Row
struct CategoryStatRow: View {
    let category: String
    let count: Int
    let percentage: Double
    
    var body: some View {
        HStack {
            Text(category)
                .bodyStyle()
                .primaryText()
                .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(count)回")
                    .bodyStyle()
                    .secondaryText()
                
                Text("(\(String(format: "%.1f", percentage))%)")
                    .captionStyle()
                    .secondaryText()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    StatisticsView(
        viewModel: TimerViewModel(),
        isPresented: .constant(true)
    )
}
