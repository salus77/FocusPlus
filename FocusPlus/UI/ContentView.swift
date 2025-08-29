import SwiftUI

// MARK: - Data Models






// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var viewModel = TimerViewModel()
    @StateObject private var tagManager = TagManager()
    @StateObject private var ambientSoundManager = AmbientSoundManager()
    @EnvironmentObject var taskPlusSyncManager: TaskPlusSyncManager
    @State private var showingBreakSheet = false
    @State private var showingHelp = false
    @State private var showingTagSelection = false
    @State private var showingRightMenu = false
    @State private var showingAmbientSoundMenu = false
    @State private var showingStatisticsSheet = false
    @State private var tagSelectionOffset: CGFloat = 0
    @State private var rightMenuOffset: CGFloat = 0
    
    // MARK: - Navigation State
    @State private var navigationState: NavigationState = .none
    
    enum NavigationState {
        case none
        case settings
        case statistics
        case tagManagement
        case taskPlusSync
    }
    
    // MARK: - Computed Properties for Navigation
    private var showingSettings: Binding<Bool> {
        Binding(
            get: { navigationState == .settings },
            set: { if !$0 { navigationState = .none } }
        )
    }
    
    private var showingStatistics: Binding<Bool> {
        Binding(
            get: { navigationState == .statistics },
            set: { if !$0 { navigationState = .none } }
        )
    }
    
    private var showingTagManagement: Binding<Bool> {
        Binding(
            get: { navigationState == .tagManagement },
            set: { if !$0 { navigationState = .none } }
        )
    }
    
    private var showingTaskPlusSync: Binding<Bool> {
        Binding(
            get: { navigationState == .taskPlusSync },
            set: { if !$0 { navigationState = .none } }
        )
    }
    
    // MARK: - Navigation Coordinator
    private func navigateTo(_ state: NavigationState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            navigationState = state
        }
    }
    
    private func dismissNavigation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            navigationState = .none
        }
    }
    
    // Apple公式推奨の環境変数を使用
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // MARK: - Main Content View
    @ViewBuilder
    private func mainContentView(geometry: GeometryProxy) -> some View {
                ZStack {
                    // 背景色を全体に適用
                    DesignSystem.Colors.background
                        .ignoresSafeArea()
                    
                    // Apple公式推奨の環境変数ベースのレイアウト制御
                    Group {
                        if horizontalSizeClass == .regular {
                            // 横置きレイアウト（Apple公式推奨）
                            landscapeLayout(geometry: geometry)
                        } else {
                            // 縦置きレイアウト
                            portraitLayout(geometry: geometry)
                        }
                    }
            
            // メニューボタンのオーバーレイ（タイマー画面のみ表示）
            if navigationState == .none {
                leftMenuButton
                rightMenuButton
                musicButton
                statisticsButton
                    }
                }
                .navigationBarHidden(true)
                .onChange(of: viewModel.state) { _, newState in
            handleTimerStateChange(newState)
        }
        .onChange(of: ambientSoundManager.selectedSound) { _, newSound in
            handleSoundSelectionChange(newSound)
        }
    }
    
    // MARK: - Timer State Change Handler
    private func handleTimerStateChange(_ newState: TimerState) {
                    if newState == .finished && viewModel.phase == .focus {
                        // 点滅アニメーション完了後にBreakSheetViewを表示
                        viewModel.onCompletionAnimationFinished = {
                            showingBreakSheet = true
                        }
                    }
        
        // 環境音の再生制御（デバッグ表示付き）
        print("🔊 Ambient Sound Debug:")
        print("  - Timer State: \(newState)")
        print("  - Selected Sound: \(ambientSoundManager.selectedSound.displayName)")
        print("  - Is Playing: \(ambientSoundManager.isPlaying)")
        
        // 選択されたサウンドがサイレントでない場合のみ再生
        if ambientSoundManager.selectedSound != .silent {
            switch newState {
            case .running:
                print("  - 🎵 Starting ambient sound...")
                ambientSoundManager.playSound()
            case .paused, .idle, .finished:
                print("  - 🔇 Stopping ambient sound...")
                ambientSoundManager.stopSound()
            }
        } else {
            print("  - 🔇 Silent mode - no sound")
            ambientSoundManager.stopSound()
        }
    }
    
    // MARK: - Sound Selection Change Handler
    private func handleSoundSelectionChange(_ newSound: AmbientSound) {
        print("🎵 Sound Selection Changed:")
        print("  - New Sound: \(newSound.displayName)")
        print("  - Current Timer State: \(viewModel.state)")
        
        // サウンド選択時の環境音制御
        if newSound == .silent {
            print("  - 🔇 Silent selected - stopping sound")
            ambientSoundManager.stopSound()
        } else if viewModel.state == .running {
            print("  - 🎵 Non-silent sound selected and timer is running - starting sound")
            ambientSoundManager.playSound()
        } else {
            print("  - ⏸️ Non-silent sound selected but timer is not running - sound will start when timer starts")
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                mainContentView(geometry: geometry)
            }
            .navigationDestination(isPresented: showingStatistics) {
                StatisticsView(viewModel: viewModel, isPresented: showingStatistics)
                    .onDisappear {
                        dismissNavigation()
                    }
            }


            .navigationDestination(isPresented: showingTaskPlusSync) {
                TaskPlusSyncView(syncManager: taskPlusSyncManager)
                    .onDisappear {
                        dismissNavigation()
                    }
            }
                    }
        .onChange(of: tagManager.selectedTag) { _, newTag in
            viewModel.currentTag = newTag
            if let tag = newTag {
                viewModel.setCurrentTask(name: tag.name, estimatedMinutes: 25, categoryColor: tag.color)
            }
        }
        .onAppear {
            // 起動直後の初期化処理
            // TagManagerのselectedTagが設定されている場合は、TimerViewModelのcurrentTagと同期
            if let selectedTag = tagManager.selectedTag {
                viewModel.currentTag = selectedTag
                viewModel.setCurrentTask(name: selectedTag.name, estimatedMinutes: 25, categoryColor: selectedTag.color)
            }
            
            // TimerViewModelの初期化完了を通知
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.onInitializationComplete()
            }
        }
        .sheet(isPresented: $showingBreakSheet) {
            BreakSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingHelp) {
            HelpView(isPresented: $showingHelp)
        }
        .sheet(isPresented: $showingAmbientSoundMenu) {
            AmbientSoundMenuView(
                soundManager: ambientSoundManager,
                isPresented: $showingAmbientSoundMenu
            )
        }
                    .sheet(isPresented: $showingStatisticsSheet) {
                StatisticsView(viewModel: viewModel, isPresented: $showingStatisticsSheet)
            }
            .sheet(isPresented: $showingTagSelection) {
                TagSelectionView(tagManager: tagManager, isPresented: $showingTagSelection)
            }
            .sheet(isPresented: showingSettings) {
                SettingsView(viewModel: viewModel, isPresented: showingSettings, navigationState: $navigationState)
            }
        // .gesture(swipeGesture) // スワイプジェスチャーを無効化
        .overlay(
            // タイマー画面のみオーバーレイを表示
            Group {
                if navigationState == .none {
                    landscapeOverlay
                }
            }
        )
    }
    
    // MARK: - Menu Button Overlays
    private var leftMenuButton: some View {
        Button(action: {
            print("🏷️ Tag Button tapped!")
            HapticsManager.shared.lightImpact()
            showingTagSelection = true
        }) {
            Image(systemName: "tag.fill")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(width: 24, height: 24)
                .background(Color.black.opacity(0.8))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .position(x: 30, y: 60)
    }
    
    private var rightMenuButton: some View {
        Button(action: {
            print("⚙️ Right Menu Button tapped!")
            HapticsManager.shared.lightImpact()
            navigateTo(.settings)
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(width: 24, height: 24)
                .background(Color.black.opacity(0.8))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .position(x: UIScreen.main.bounds.width - 30, y: 60)
    }
    
    // MARK: - Music Button
    private var musicButton: some View {
        Button(action: {
            print("🎵 Music Button tapped!")
            HapticsManager.shared.lightImpact()
            showingAmbientSoundMenu = true
        }) {
            Image(systemName: ambientSoundManager.isPlaying ? "speaker.wave.2.fill" : "music.note")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(width: 24, height: 24)
                .background(Color.black.opacity(0.8))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .position(x: UIScreen.main.bounds.width - 30, y: UIScreen.main.bounds.height - 100)
    }
    
    // MARK: - Statistics Button
    private var statisticsButton: some View {
        Button(action: {
            print("📊 Statistics Button tapped!")
            HapticsManager.shared.lightImpact()
            showingStatisticsSheet = true
        }) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(width: 24, height: 24)
                .background(Color.black.opacity(0.8))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .position(x: 30, y: UIScreen.main.bounds.height - 100)
    }
    
    // MARK: - Layout Views
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
            VStack(spacing: 0) {
                Spacer()
                .frame(height: 110) // 上部のスペースを調整
            
            // タグ名表示
            VStack(spacing: 16) {
                if let tag = tagManager.selectedTag {
                    HStack(spacing: 8) {
                        Image(systemName: tag.icon)
                            .foregroundColor(tag.color)
                        Text(tag.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                            .foregroundColor(tag.color)
                    }
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                } else {
                    Text("タグを選択してください")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                }
                
                // ポモドーロ数のドット（タグ表示の下）
                CompletedCountView(
                    completedCount: viewModel.completedCountToday,
                    hourlyData: viewModel.hourlyCompletedCounts(for: Date()),
                    hourlyColors: viewModel.hourlyColorsForToday
                )
                .padding(.horizontal, 24)
                
                // Circular Dial View
                CircularDialView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
                
                Spacer()
                
                // Bottom Controls
                BottomControlsView(viewModel: viewModel)
                    .padding(.bottom, 50)
                    .padding(.horizontal, 24)
            }
        }
    
    // MARK: - Apple公式推奨の横置きレイアウト
    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        // 横置きレイアウト（Apple公式推奨の実装）
        ZStack {
        HStack(spacing: 0) {
            // 左側: 統計情報
            VStack(spacing: 16) {
                Spacer()
                
                Spacer()
            }
            .frame(width: geometry.size.width * 0.22)
            .padding(.leading, 20)
            
            // 中央: プログレス円とタスク名
            HStack(spacing: 0) {
                // 左側: ポモドーロ数のドット
                VStack {
                Spacer()
                CompletedCountView(
                    completedCount: viewModel.completedCountToday,
                    hourlyData: viewModel.hourlyCompletedCounts(for: Date()),
                    hourlyColors: viewModel.hourlyColorsForToday
                )
                    .padding(.horizontal, 24)
                Spacer()
            }
                .frame(width: geometry.size.width * 0.12)
            
                // 中央: タグ名表示とプログレス円
            VStack(spacing: 20) {
                    // タグ名表示
                    if let tag = tagManager.selectedTag {
                        HStack(spacing: 8) {
                            Image(systemName: tag.icon)
                                .foregroundColor(tag.color)
                            Text(tag.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                                .foregroundColor(tag.color)
                        }
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                } else {
                        Text("タグを選択してください")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                }
                
                // プログレス円
                CircularDialView(viewModel: viewModel)
                        .frame(width: min(geometry.size.width * 0.45, geometry.size.height * 0.85), height: min(geometry.size.width * 0.45, geometry.size.height * 0.85))
                }
                .frame(width: geometry.size.width * 0.38)
                
                // 右側: 空のスペース（タイマーを中央に配置するため）
                VStack {
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.12)
            }
            .frame(maxWidth: .infinity)
            
            // 右側: タイマーコントロールボタン
            VStack(spacing: 16) {
                Spacer()
                
                BottomControlsView(viewModel: viewModel)
                Spacer()
            }
            .frame(width: geometry.size.width * 0.22)
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 横置き時の4つのアイコン
            // 左上: タスク管理
            Button(action: {
                print("🏷️ Tag Button tapped!")
                HapticsManager.shared.lightImpact()
                showingTagSelection = true
            }) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .position(x: 30, y: 60)
            
            // 右上: 設定
            Button(action: {
                print("⚙️ Right Menu Button tapped!")
                HapticsManager.shared.lightImpact()
                navigateTo(.settings)
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .position(x: geometry.size.width - 30, y: 60)
            
            // 右下: 音楽
            Button(action: {
                print("🎵 Music Button tapped!")
                HapticsManager.shared.lightImpact()
                showingAmbientSoundMenu = true
            }) {
                Image(systemName: ambientSoundManager.isPlaying ? "speaker.wave.2.fill" : "music.note")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .position(x: geometry.size.width - 30, y: geometry.size.height - 100)
            

        }
    }
    
    // MARK: - Right Menu Overlay (Disabled - Direct Navigation)
    @ViewBuilder
    private var rightMenuOverlay: some View {
        // 右側メニューは無効化 - 直接ナビゲーションに変更
        EmptyView()
    }
    
        private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Apple公式推奨: onChangedでは視覚的フィードバックのみ
                // ドラッグ中のオフセット値を更新（状態変更なし）
                // スワイプジェスチャーは無効化
            }
            .onEnded { value in
                // Apple公式推奨: onEndedで実際の状態変更
                print("🎯 Swipe onEnded - translation: \(value.translation.width), threshold: 100")
                // スワイプジェスチャーは無効化
            }
    }
    
    // MARK: - Computed Properties for Landscape Control
    @ViewBuilder
    private var landscapeOverlay: some View {
        // 縦横置き時ともにオーバーレイを表示
        ZStack {
            // 左側: タグ管理（無効化）
        HStack {
                EmptyView()
            Spacer()
            }
            
            // 右側: 右側メニュー
            HStack {
                Spacer()
            rightMenuOverlay
            }
            

        }
    }
}

// MARK: - Completed Count View
struct CompletedCountView: View {
    let completedCount: Int
    let hourlyData: [Int]
    let hourlyColors: [Color]
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // 時間ごとのデータから完了順序に沿った色配列を生成
    private var completedColors: [Color] {
        var colors: [Color] = []
        for hour in 0..<24 {
            let count = hourlyData[hour]
            let color = hourlyColors[hour]
            for _ in 0..<count {
                colors.append(color)
            }
        }
        return colors
    }
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // 縦置きモード（横並び）
        HStack(spacing: 8) {
            ForEach(0..<min(completedCount, 10), id: \.self) { index in
                        let dotColor = index < completedColors.count ? completedColors[index] : DesignSystem.Colors.neonBlue
                Circle()
                            .fill(dotColor)
                        .frame(width: 12, height: 12)
                        .opacity(0.9)
                        .shadow(
                                color: dotColor.opacity(0.6),
                            radius: 2,
                            x: 0,
                            y: 0
                        )
                }
                
                if completedCount > 10 {
                    Text("+\(completedCount - 10)")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            } else {
                // 横置きモード（縦並び）
                VStack(spacing: 8) {
                    ForEach(0..<min(completedCount, 10), id: \.self) { index in
                        let dotColor = index < completedColors.count ? completedColors[index] : DesignSystem.Colors.neonBlue
                        Circle()
                            .fill(dotColor)
                            .frame(width: 12, height: 12)
                            .opacity(0.9)
                            .shadow(
                                color: dotColor.opacity(0.6),
                                radius: 2,
                                x: 0,
                                y: 0
                            )
                    }
                    
                    if completedCount > 10 {
                        Text("+\(completedCount - 10)")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            }
        }
    }
}



// MARK: - Break Sheet View
struct BreakSheetView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(DesignSystem.Colors.success)
                
                Text("セッション完了")
                    .largeTitleStyle()
                    .primaryText()
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    viewModel.startBreak()
                    dismiss()
                }) {
                    Text("休憩を開始")
                        .headlineStyle()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    viewModel.reset()
                    dismiss()
                }) {
                    Text("新しいセッションを開始")
                        .headlineStyle()
                        .foregroundColor(DesignSystem.Colors.neonBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DesignSystem.Colors.neonBlue.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(DesignSystem.Colors.background)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Right Menu Overlay
struct RightMenuOverlay: View {
    let onSettingsTapped: () -> Void
    let onStatisticsTapped: () -> Void
    let onTaskManagementTapped: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            
            // メインコンテンツ
            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Text("メニュー")
                        .title2Style()
                        .primaryText()
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // メニューアイテム
                VStack(spacing: 0) {
                    // タスク管理
                    MenuItem(
                        icon: "list.bullet",
                        title: "タスク管理",
                        color: .orange
                    ) {
                        print("📋 Task Management MenuItem tapped!")
                        HapticsManager.shared.lightImpact()
                        onTaskManagementTapped()
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // 統計
                    MenuItem(
                        icon: "chart.bar.fill",
                        title: "統計",
                        color: .green
                    ) {
                        print("📊 Statistics MenuItem tapped!")
                        HapticsManager.shared.lightImpact()
                        onStatisticsTapped()
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // 設定
                    MenuItem(
                        icon: "gearshape.fill",
                        title: "設定",
                        color: .blue
                    ) {
                        print("🔧 Settings MenuItem tapped!")
                        HapticsManager.shared.lightImpact()
                        onSettingsTapped()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
            }
            .frame(width: 300)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.Layout.cornerRadius)
            .shadow(radius: 10)
        }
    }
}

// MARK: - Menu Item
struct MenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            print("🎯 MenuItem Button tapped for: \(title)")
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
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
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ContentView()
}

