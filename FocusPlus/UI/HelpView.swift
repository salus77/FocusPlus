import SwiftUI

struct HelpView: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("ヘルプ")
                        .title2Style()
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
                
                // Help Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Timer Usage
                        HelpSection(
                            title: "タイマーの使い方",
                            icon: "timer",
                            content: [
                                "円形のダイヤルをドラッグして時間を設定",
                                "中央の再生ボタンでタイマーを開始/一時停止",
                                "リセットボタンで時間を元に戻す",
                                "スキップボタンで現在のセッションを完了"
                            ]
                        )
                        
                        // Menu Access
                        HelpSection(
                            title: "メニューアクセス",
                            icon: "hand.draw",
                            content: [
                                "左上のオレンジボタン: タスク管理を表示",
                                "右上の青ボタン: メニューを表示（タスク管理・統計・設定）",
                                "上から下へスワイプ: 統計画面を表示"
                            ]
                        )
                        
                        // Task Management
                        HelpSection(
                            title: "タスク管理",
                            icon: "checklist",
                            content: [
                                "カテゴリ別にタスクを整理",
                                "タスクを選択してタイマーに設定",
                                "優先度と推定時間を管理",
                                "完了したタスクを記録"
                            ]
                        )
                        
                        // Statistics
                        HelpSection(
                            title: "統計情報",
                            icon: "chart.bar.fill",
                            content: [
                                "日別・月別の完了数を表示",
                                "集中時間の合計を記録",
                                "セッションの平均時間を計算",
                                "最長ストリークを追跡"
                            ]
                        )
                        
                        // Tips
                        HelpSection(
                            title: "使い方のコツ",
                            icon: "lightbulb.fill",
                            content: [
                                "25分の集中セッションを基本とする",
                                "セッション間で5分の休憩を取る",
                                "4セッション後に長い休憩を取る",
                                "タスクの優先度に応じて時間を調整"
                            ]
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
            .background(DesignSystem.Colors.background)
        }
        .navigationBarHidden(true)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Help Section
struct HelpSection: View {
    let title: String
    let icon: String
    let content: [String]
    
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
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(content, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(DesignSystem.Colors.neonBlue)
                            .padding(.top, 6)
                        
                        Text(item)
                            .bodyStyle()
                            .secondaryText()
                        
                        Spacer()
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

#Preview {
    HelpView(isPresented: .constant(true))
}
