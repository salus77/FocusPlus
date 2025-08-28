import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskPlusSyncManager: TaskPlusSyncManager
    @Binding var navigationState: ContentView.NavigationState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Sound Settings
                SettingsSection(title: "サウンド") {
                    SettingsRow(
                        icon: "speaker.wave.2.fill",
                        title: "サウンドを有効にする",
                        isOn: $viewModel.soundEnabled
                    )
                }
                
                // Haptics Settings
                SettingsSection(title: "触覚フィードバック") {
                    SettingsRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "触覚フィードバックを有効にする",
                        isOn: $viewModel.hapticsEnabled
                    )
                }
                
                // Timer Settings
                SettingsSection(title: "タイマー設定") {
                    VStack(spacing: 0) {
                        SettingsSliderRow(
                            icon: "timer",
                            title: "集中時間",
                            value: $viewModel.focusDuration,
                            range: 5...60,
                            unit: "分"
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        SettingsSliderRow(
                            icon: "pause.fill",
                            title: "休憩時間",
                            value: $viewModel.breakDuration,
                            range: 1...30,
                            unit: "分"
                        )
                    }
                }
                
                // TaskPlus Integration
                SettingsSection(title: "TaskPlus連携") {
                    Button(action: {
                        navigationState = .taskPlusSync
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "icloud.fill")
                                .font(.title3)
                                .foregroundColor(DesignSystem.Colors.neonBlue)
                                .frame(width: 24)
                            
                            Text("TaskPlus同期設定")
                                .bodyStyle()
                                .primaryText()
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // App Info
                SettingsSection(title: "アプリ情報") {
                    VStack(spacing: 0) {
                        SettingsInfoRow(
                            icon: "info.circle.fill",
                            title: "バージョン",
                            value: "1.0.0"
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        SettingsInfoRow(
                            icon: "person.fill",
                            title: "開発者",
                            value: "Yasutaka Otsubo"
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // 設定画面が表示されるときの処理
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .headlineStyle()
                .primaryText()
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.neonBlue)
                .frame(width: 24)
            
            Text(title)
                .bodyStyle()
                .primaryText()
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.accent))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Settings Slider Row
struct SettingsSliderRow: View {
    let icon: String
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(DesignSystem.Colors.neonBlue)
                    .frame(width: 24)
                
                Text(title)
                    .bodyStyle()
                    .primaryText()
                
                Spacer()
                
                Text("\(Int(value))\(unit)")
                    .subheadlineStyle()
                    .secondaryText()
            }
            
            Slider(value: $value, in: range, step: 1)
                .accentColor(DesignSystem.Colors.accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.neonBlue)
                .frame(width: 24)
            
            Text(title)
                .bodyStyle()
                .primaryText()
            
            Spacer()
            
            Text(value)
                .subheadlineStyle()
                .secondaryText()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    SettingsView(viewModel: TimerViewModel(), isPresented: .constant(true), navigationState: .constant(.none))
}
