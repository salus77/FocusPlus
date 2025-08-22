import SwiftUI

// MARK: - Data Models
struct TaskCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let tasks: [TaskItem]
}

struct TaskItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let estimatedMinutes: Int
    let priority: TaskPriority
    let isCompleted: Bool
}

enum TaskPriority: String, CaseIterable {
    case low = "低"
    case medium = "中"
    case high = "高"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Sample Data
let sampleCategories = [
    TaskCategory(
        name: "仕事",
        icon: "briefcase.fill",
        color: .blue,
        tasks: [
            TaskItem(name: "メール処理", description: "未読メールの確認と返信", estimatedMinutes: 30, priority: .medium, isCompleted: false),
            TaskItem(name: "会議準備", description: "明日の会議資料の準備", estimatedMinutes: 60, priority: .high, isCompleted: false),
            TaskItem(name: "レポート作成", description: "月次レポートの作成", estimatedMinutes: 90, priority: .medium, isCompleted: false)
        ]
    ),
    TaskCategory(
        name: "プロジェクト",
        icon: "folder.fill",
        color: .purple,
        tasks: [
            TaskItem(name: "アプリ開発", description: "新機能の実装", estimatedMinutes: 120, priority: .high, isCompleted: false),
            TaskItem(name: "デザイン確認", description: "UIデザインのレビュー", estimatedMinutes: 45, priority: .medium, isCompleted: false)
        ]
    ),
    TaskCategory(
        name: "学習",
        icon: "book.fill",
        color: .green,
        tasks: [
            TaskItem(name: "SwiftUI学習", description: "新しいコンポーネントの学習", estimatedMinutes: 60, priority: .medium, isCompleted: false),
            TaskItem(name: "英語学習", description: "オンライン英会話", estimatedMinutes: 30, priority: .low, isCompleted: false)
        ]
    ),
    TaskCategory(
        name: "個人",
        icon: "person.fill",
        color: .orange,
        tasks: [
            TaskItem(name: "運動", description: "ジムでのトレーニング", estimatedMinutes: 60, priority: .medium, isCompleted: false),
            TaskItem(name: "読書", description: "技術書の読書", estimatedMinutes: 45, priority: .low, isCompleted: false)
        ]
    )
]

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var viewModel = TimerViewModel()
    @State private var showingBreakSheet = false
    @State private var showingStatistics = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var showingTaskManager = false
    @State private var taskManagerOffset: CGFloat = 0
    @State private var orientation = UIDeviceOrientation.portrait
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                if orientation.isLandscape {
                    // 横置きレイアウト
                    landscapeLayout(geometry: geometry)
                } else {
                    // 縦置きレイアウト
                    portraitLayout
                }
            }
        }
        .onRotate { newOrientation in
            orientation = newOrientation
        }
        .onChange(of: viewModel.state) { _, newState in
            if newState == .finished && viewModel.phase == .focus {
                showingBreakSheet = true
            }
        }
        .sheet(isPresented: $showingBreakSheet) {
            BreakSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView(viewModel: viewModel, isPresented: $showingStatistics)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel, isPresented: $showingSettings)
        }
        .sheet(isPresented: $showingHelp) {
            HelpView(isPresented: $showingHelp)
        }
        .overlay(taskManagerOverlay)
        .gesture(swipeGesture)
    }
    
    // MARK: - Layout Views
    @ViewBuilder
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // Completed Count View
            CompletedCountView(completedCount: viewModel.completedCountToday)
                .padding(.top, 60)
                .padding(.horizontal, 24)
                .onTapGesture {
                    HapticsManager.shared.lightImpact()
                    showingStatistics = true
                }
            
            Spacer()
            
            // Circular Dial View
            CircularDialView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
            
            // Bottom Controls
            BottomControlsView(viewModel: viewModel)
                .padding(.bottom, 50)
                .padding(.horizontal, 24)
        }
    }
    
    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 30) {
            // 左側: ポモドーロ数のドット（縦に並べる）
            VStack(spacing: 16) {
                Spacer()
                CompletedCountView(completedCount: viewModel.completedCountToday)
                    .onTapGesture {
                        HapticsManager.shared.lightImpact()
                        showingStatistics = true
                    }
                Spacer()
            }
            .frame(width: geometry.size.width * 0.2)
            
            // 中央: プログレス円（より大きく表示）
            CircularDialView(viewModel: viewModel)
                .frame(width: geometry.size.height * 0.9, height: geometry.size.height * 0.9)
            
            // 右側: タイマー開始/停止ボタン（縦に並べる）
            VStack(spacing: 16) {
                Spacer()
                BottomControlsView(viewModel: viewModel)
                Spacer()
            }
            .frame(width: geometry.size.width * 0.2)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var taskManagerOverlay: some View {
        Group {
            if showingTaskManager {
                TaskManagerOverlay(
                    categories: sampleCategories,
                    showingTaskManager: $showingTaskManager,
                    taskManagerOffset: $taskManagerOffset,
                    onTaskSelected: { task in
                        print("Selected task: \(task.name)")
                    }
                )
                .transition(.move(edge: .leading))
            }
        }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
                               .onChanged { value in
                       // 左から右へのスワイプでタスク管理
                       if value.translation.width > 0 && abs(value.translation.width) > 50 {
                           withAnimation(.easeOut(duration: 0.3)) {
                               showingTaskManager = true
                               taskManagerOffset = value.translation.width
                           }
                       }
                   }
                   .onEnded { value in
                       if value.translation.width > 100 {
                           // 左から右へのスワイプでタスク管理を表示
                           withAnimation(.easeOut(duration: 0.3)) {
                               showingTaskManager = true
                               taskManagerOffset = 0
                           }
                       } else if value.translation.width < -100 {
                           // 右から左へのスワイプで設定メニューを表示
                           withAnimation(.easeOut(duration: 0.3)) {
                               HapticsManager.shared.lightImpact()
                               showingSettings = true
                           }
                       } else {
                           // スワイプが不十分な場合は非表示
                           withAnimation(.easeOut(duration: 0.3)) {
                               showingTaskManager = false
                               taskManagerOffset = 0
                           }
                       }
                   }
    }
}

// MARK: - Completed Count View
struct CompletedCountView: View {
    let completedCount: Int
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // 縦置きモード（横並び）
                HStack(spacing: 8) {
                    ForEach(0..<min(completedCount, 10), id: \.self) { index in
                        Circle()
                            .fill(DesignSystem.Colors.neonBlue)
                            .frame(width: 12, height: 12)
                            .opacity(0.9)
                            .shadow(
                                color: DesignSystem.Colors.neonBlue.opacity(0.6),
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
                        Circle()
                            .fill(DesignSystem.Colors.neonBlue)
                            .frame(width: 12, height: 12)
                            .opacity(0.9)
                            .shadow(
                                color: DesignSystem.Colors.neonBlue.opacity(0.6),
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

// MARK: - Task Manager Overlay
struct TaskManagerOverlay: View {
    let categories: [TaskCategory]
    @Binding var showingTaskManager: Bool
    @Binding var taskManagerOffset: CGFloat
    let onTaskSelected: (TaskItem) -> Void
    
    @State private var selectedCategory: TaskCategory?
    @State private var selectedTask: TaskItem?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // メインコンテンツ
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("タスク管理")
                            .title2Style()
                            .primaryText()
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showingTaskManager = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(DesignSystem.Colors.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // コンテンツ (CategoryListView or TaskListView)
                    if let selectedCategory = selectedCategory {
                        TaskListView(
                            category: selectedCategory,
                            onTaskSelected: { task in
                                onTaskSelected(task)
                            }
                        )
                    } else {
                        // カテゴリリストを固定のVStackに変更
                        VStack(spacing: 16) {
                            ForEach(categories, id: \.id) { category in
                                CategoryCard(
                                    category: category,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCategory = category
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.8)
                .background(DesignSystem.Colors.background)
                .cornerRadius(DesignSystem.Layout.cornerRadius)
                .shadow(radius: 10)
                .offset(x: taskManagerOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                taskManagerOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < -geometry.size.width * 0.3 {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showingTaskManager = false
                                    taskManagerOffset = 0
                                }
                            } else {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    taskManagerOffset = 0
                                }
                            }
                        }
                )
                Spacer()
            }
        }
    }
}

// MARK: - Category List View
struct CategoryListView: View {
    let categories: [TaskCategory]
    let onCategorySelected: (TaskCategory) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(categories, id: \.id) { category in
                CategoryCard(
                    category: category,
                    onTap: {
                        onCategorySelected(category)
                    }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: TaskCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.color)
                    .frame(width: 40, height: 40)
                    .background(category.color.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .headlineStyle()
                        .primaryText()
                    
                    Text("\(category.tasks.count)個のタスク")
                        .captionStyle()
                        .secondaryText()
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Task List View
struct TaskListView: View {
    let category: TaskCategory
    let onTaskSelected: (TaskItem) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: {
                    // Go back to category list
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline)
                        Text(category.name)
                            .headlineStyle()
                    }
                    .foregroundColor(DesignSystem.Colors.neonBlue)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Task list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(category.tasks, id: \.id) { task in
                        TaskCard(
                            task: task,
                            onTap: {
                                onTaskSelected(task)
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Task Card
struct TaskCard: View {
    let task: TaskItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.name)
                        .headlineStyle()
                        .primaryText()
                    
                    Text(task.description)
                        .subheadlineStyle()
                        .secondaryText()
                    
                    HStack(spacing: 12) {
                        Label("\(task.estimatedMinutes)分", systemImage: "clock")
                            .captionStyle()
                            .secondaryText()
                        
                        Label(task.priority.rawValue, systemImage: "flag.fill")
                            .captionStyle()
                            .foregroundColor(task.priority.color)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
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
                
                Text("お疲れ様でした")
                    .title3Style()
                    .secondaryText()
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

// MARK: - Device Orientation Detection
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

#Preview {
    ContentView()
}
