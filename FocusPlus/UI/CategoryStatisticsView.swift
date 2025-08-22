import SwiftUI

struct CategoryStatisticsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("カテゴリ別統計")
                        .largeTitleStyle()
                        .primaryText()
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(DesignSystem.Colors.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 32)
                
                // Category Statistics Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Selected Date
                        VStack(spacing: 16) {
                            Text("選択日: \(formatDate(viewModel.selectedDate))")
                                .subheadlineStyle()
                                .secondaryText()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Category List
                        let categoryStats = viewModel.getCategoryStatistics(for: viewModel.selectedDate)
                        if categoryStats.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 48))
                                    .foregroundColor(DesignSystem.Colors.secondary)
                                
                                Text("カテゴリ別のデータがありません")
                                    .bodyStyle()
                                    .secondaryText()
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 40)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(Array(categoryStats.sorted(by: { $0.value > $1.value })), id: \.key) { category, count in
                                    CategoryStatRow(
                                        categoryName: category,
                                        count: count,
                                        totalTime: count * Int(viewModel.focusDuration)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Summary
                        if !categoryStats.isEmpty {
                            StatCard(
                                title: "カテゴリ別サマリー",
                                icon: "chart.pie.fill",
                                items: [
                                    StatItem(label: "カテゴリ数", value: "\(categoryStats.count)個"),
                                    StatItem(label: "総完了数", value: "\(categoryStats.values.reduce(0, +))回"),
                                    StatItem(label: "総集中時間", value: "\(categoryStats.values.reduce(0, +) * Int(viewModel.focusDuration))分")
                                ]
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct CategoryStatRow: View {
    let categoryName: String
    let count: Int
    let totalTime: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            Circle()
                .fill(DesignSystem.Colors.neonBlue)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "folder.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                )
            
            // Category Info
            VStack(alignment: .leading, spacing: 4) {
                Text(categoryName)
                    .headlineStyle()
                    .primaryText()
                
                Text("\(count)回完了")
                    .captionStyle()
                    .secondaryText()
            }
            
            Spacer()
            
            // Time Info
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(totalTime)分")
                    .headlineStyle()
                    .primaryText()
                
                Text("集中時間")
                    .captionStyle()
                    .secondaryText()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    CategoryStatisticsView(
        viewModel: TimerViewModel(),
        isPresented: .constant(true)
    )
    .background(DesignSystem.Colors.background)
}
