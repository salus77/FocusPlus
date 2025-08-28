import SwiftUI

// MARK: - Data Models
struct TaskCategory: Identifiable, Codable {
    var id = UUID()
    var name: String
    var icon: String
    var color: Color
    var tasks: [TaskItem]
    
    init(name: String, icon: String, color: Color, tasks: [TaskItem] = []) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.tasks = tasks
    }
    
    // ColorのCodable対応
    enum CodingKeys: String, CodingKey {
        case id, name, icon, tasks, colorRed, colorGreen, colorBlue, colorOpacity
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        tasks = try container.decode([TaskItem].self, forKey: .tasks)
        
        let red = try container.decode(Double.self, forKey: .colorRed)
        let green = try container.decode(Double.self, forKey: .colorGreen)
        let blue = try container.decode(Double.self, forKey: .colorBlue)
        let opacity = try container.decode(Double.self, forKey: .colorOpacity)
        color = Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(tasks, forKey: .tasks)
        
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        try container.encode(Double(red), forKey: .colorRed)
        try container.encode(Double(green), forKey: .colorGreen)
        try container.encode(Double(blue), forKey: .colorBlue)
        try container.encode(Double(alpha), forKey: .colorOpacity)
    }
}

struct TaskItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var estimatedMinutes: Int
    var priority: TaskPriority
    var isCompleted: Bool
    
    init(name: String, description: String, estimatedMinutes: Int, priority: TaskPriority, isCompleted: Bool = false) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.estimatedMinutes = estimatedMinutes
        self.priority = priority
        self.isCompleted = isCompleted
    }
}

enum TaskPriority: String, CaseIterable, Codable {
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

// MARK: - Task Manager
class TaskManager: ObservableObject {
    @Published var categories: [TaskCategory] = []
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadCategories()
    }
    
    // MARK: - Data Persistence
    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            userDefaults.set(encoded, forKey: "taskCategories")
        }
    }
    
    private func loadCategories() {
        if let data = userDefaults.data(forKey: "taskCategories"),
           let decoded = try? JSONDecoder().decode([TaskCategory].self, from: data) {
            categories = decoded
        } else {
            categories = sampleCategories
            saveCategories()
        }
    }
    
    // MARK: - Category Operations
    func addCategory(_ category: TaskCategory) {
        categories.append(category)
        saveCategories()
    }
    
    func updateCategory(_ category: TaskCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }
    
    func deleteCategory(_ category: TaskCategory) {
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    // MARK: - Task Operations
    func addTask(_ task: TaskItem, to categoryId: UUID) {
        if let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }) {
            categories[categoryIndex].tasks.append(task)
            saveCategories()
        }
    }
    
    func updateTask(_ task: TaskItem, in categoryId: UUID) {
        if let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }),
           let taskIndex = categories[categoryIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            categories[categoryIndex].tasks[taskIndex] = task
            saveCategories()
        }
    }
    
    func deleteTask(_ taskId: UUID, from categoryId: UUID) {
        if let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }) {
            categories[categoryIndex].tasks.removeAll { $0.id == taskId }
            saveCategories()
        }
    }
    
    func deleteTask(_ task: TaskItem, from category: TaskCategory) {
        if let categoryIndex = categories.firstIndex(where: { $0.id == category.id }) {
            categories[categoryIndex].tasks.removeAll { $0.id == task.id }
            saveCategories()
        }
    }
    
    func toggleTaskCompletion(_ taskId: UUID, in categoryId: UUID) {
        if let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }),
           let taskIndex = categories[categoryIndex].tasks.firstIndex(where: { $0.id == taskId }) {
            categories[categoryIndex].tasks[taskIndex].isCompleted.toggle()
            saveCategories()
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
    @StateObject private var taskManager = TaskManager()
    @EnvironmentObject var taskPlusSyncManager: TaskPlusSyncManager
    @State private var showingBreakSheet = false
    @State private var showingHelp = false
    @State private var showingTaskManager = false
    @State private var showingRightMenu = false
    @State private var taskManagerOffset: CGFloat = 0
    @State private var rightMenuOffset: CGFloat = 0
    
    // MARK: - Navigation State
    @State private var navigationState: NavigationState = .none
    
    enum NavigationState {
        case none
        case settings
        case statistics
        case taskManagement
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
    
    private var showingTaskManagement: Binding<Bool> {
        Binding(
            get: { navigationState == .taskManagement },
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
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
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
                }
                .navigationBarHidden(true)
                .onChange(of: viewModel.state) { _, newState in
                    if newState == .finished && viewModel.phase == .focus {
                        // 点滅アニメーション完了後にBreakSheetViewを表示
                        viewModel.onCompletionAnimationFinished = {
                            showingBreakSheet = true
                        }
                    }
                }
            }
            .navigationDestination(isPresented: showingStatistics) {
                StatisticsView(viewModel: viewModel, isPresented: showingStatistics)
                    .onDisappear {
                        dismissNavigation()
                    }
            }
            .navigationDestination(isPresented: showingSettings) {
                SettingsView(viewModel: viewModel, isPresented: showingSettings, navigationState: $navigationState)
                    .onDisappear {
                        dismissNavigation()
                    }
            }
            .navigationDestination(isPresented: showingTaskManagement) {
                TaskManagementView(taskManager: taskManager)
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
        .sheet(isPresented: $showingBreakSheet) {
            BreakSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingHelp) {
            HelpView(isPresented: $showingHelp)
        }
        .gesture(swipeGesture)
        .overlay(landscapeOverlay)
    }
    
    // MARK: - Layout Views
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
            VStack(spacing: 0) {
                // Completed Count View
            CompletedCountView(
                completedCount: viewModel.completedCountToday,
                hourlyData: viewModel.hourlyCompletedCounts(for: Date()),
                hourlyColors: viewModel.hourlyColorsForToday
            )
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                .onTapGesture {
                    HapticsManager.shared.lightImpact()
                    navigateTo(.statistics)
                }
                
                Spacer()
            
            // タスク名表示
            VStack(spacing: 16) {
                if !viewModel.currentTaskName.isEmpty {
                    Text(viewModel.currentTaskName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.currentTaskCategoryColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                } else {
                    Text("タスクを選択してください")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                }
                
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
        HStack(spacing: 0) {
            // 左側: ポモドーロ数のドットと統計
            VStack(spacing: 16) {
                Spacer()
                CompletedCountView(
                    completedCount: viewModel.completedCountToday,
                    hourlyData: viewModel.hourlyCompletedCounts(for: Date()),
                    hourlyColors: viewModel.hourlyColorsForToday
                )
                    .onTapGesture {
                        HapticsManager.shared.lightImpact()
                        navigateTo(.statistics)
                    }
                Spacer()
            }
            .frame(width: geometry.size.width * 0.25)
            .padding(.leading, 20)
            
            // 中央: プログレス円とタスク名
            VStack(spacing: 20) {
                // タスク名表示
                if !viewModel.currentTaskName.isEmpty {
                    Text(viewModel.currentTaskName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.currentTaskCategoryColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                } else {
                    Text("タスクを選択してください")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                }
                
                // プログレス円
                CircularDialView(viewModel: viewModel)
                    .frame(width: min(geometry.size.width * 0.4, geometry.size.height * 0.85), height: min(geometry.size.width * 0.4, geometry.size.height * 0.85))
            }
            .frame(maxWidth: .infinity)
            
            // 右側: タイマーコントロールボタン
            VStack(spacing: 16) {
                Spacer()
                
                BottomControlsView(viewModel: viewModel)
                Spacer()
            }
            .frame(width: geometry.size.width * 0.25)
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var taskManagerOverlay: some View {
        Group {
            if showingTaskManager {
                TaskManagerOverlay(
                    taskManager: taskManager,
                    showingTaskManager: $showingTaskManager,
                    taskManagerOffset: $taskManagerOffset,
                    onTaskSelected: { task, category in
                        viewModel.setCurrentTask(name: task.name, estimatedMinutes: task.estimatedMinutes, categoryColor: category.color)
                        // カテゴリの色を更新
                        viewModel.updateCurrentTaskCategoryColor(category.color)
                        print("✅ Hiding Task Manager after task selection")
                        showingTaskManager = false
                        taskManagerOffset = 0
                        print("✅ Selected task: \(task.name) from category: \(category.name)")
                    }
                )
                .transition(.move(edge: .leading))
                .onAppear {
                    print("🔄 Task Manager Overlay - showing: \(showingTaskManager)")
                }
            }
        }
    }
    
    // MARK: - Right Menu Overlay
    @ViewBuilder
    private var rightMenuOverlay: some View {
        Group {
            if showingRightMenu {
                RightMenuOverlay(
                    onSettingsTapped: {
                        print("⚙️ Settings tapped, hiding right menu")
                        HapticsManager.shared.lightImpact()
                        showingRightMenu = false
                        rightMenuOffset = 0
                        navigateTo(.settings)
                    },
                    onStatisticsTapped: {
                        print("📊 Statistics tapped, hiding right menu")
                        HapticsManager.shared.lightImpact()
                        showingRightMenu = false
                        rightMenuOffset = 0
                        navigateTo(.statistics)
                    },
                    onTaskManagementTapped: {
                        print("📋 Task Management tapped, hiding right menu")
                        HapticsManager.shared.lightImpact()
                        showingRightMenu = false
                        rightMenuOffset = 0
                        navigateTo(.taskManagement)
                    },
                    onClose: {
                        print("❌ Close button tapped, hiding right menu")
                        HapticsManager.shared.lightImpact()
                        showingRightMenu = false
                        rightMenuOffset = 0
                    }
                )
                .offset(x: rightMenuOffset)
                .transition(.move(edge: .trailing))
                .onAppear {
                    print("🔄 Right Menu Overlay - showing: \(showingRightMenu)")
                }
            }
        }
    }
    
        private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Apple公式推奨: onChangedでは視覚的フィードバックのみ
                // ドラッグ中のオフセット値を更新（状態変更なし）
                print("🔄 Swipe onChanged - translation: \(value.translation.width), showingTaskManager: \(showingTaskManager), showingRightMenu: \(showingRightMenu)")
                
                if value.translation.width > 0 {
                    // 右から左へのドラッグ（右側メニューを閉じる）
                    if showingRightMenu {
                        rightMenuOffset = value.translation.width
                    } else {
                        taskManagerOffset = value.translation.width
                    }
                } else if value.translation.width < 0 {
                    // 左から右へのドラッグ（左側メニューを閉じる）
                    if showingTaskManager {
                        taskManagerOffset = abs(value.translation.width)
                    } else {
                        rightMenuOffset = abs(value.translation.width)
                    }
                }
            }
            .onEnded { value in
                // Apple公式推奨: onEndedで実際の状態変更
                print("🎯 Swipe onEnded - translation: \(value.translation.width), threshold: 100")
                print("📊 Before state - showingTaskManager: \(showingTaskManager), showingRightMenu: \(showingRightMenu)")
                
                if value.translation.width > 100 {
                    // 右から左へのスワイプ
                    if showingRightMenu {
                        // 右側メニューを閉じる
                        print("✅ Closing Right Menu (right-to-left swipe)")
                        withAnimation(.easeOut(duration: 0.3)) {
                            HapticsManager.shared.lightImpact()
                            showingRightMenu = false
                            rightMenuOffset = 0
                        }
                    } else if !showingRightMenu {
                        // 左から右へのスワイプでタスク管理を表示
                        print("✅ Showing Task Manager (left swipe)")
                        withAnimation(.easeOut(duration: 0.3)) {
                            HapticsManager.shared.lightImpact()
                            showingTaskManager = true
                            taskManagerOffset = 0
                            // 右側メニューを確実に非表示
                            showingRightMenu = false
                            rightMenuOffset = 0
                        }
                    }
                } else if value.translation.width < -100 {
                    // 左から右へのスワイプ
                    if showingTaskManager {
                        // 左側メニューを閉じる
                        print("✅ Closing Task Manager (left-to-right swipe)")
                        withAnimation(.easeOut(duration: 0.3)) {
                            HapticsManager.shared.lightImpact()
                            showingTaskManager = false
                            taskManagerOffset = 0
                        }
                    } else if !showingTaskManager {
                        // 右から左へのスワイプで右側メニューを表示
                        print("✅ Showing Right Menu (right swipe)")
                        withAnimation(.easeOut(duration: 0.3)) {
                            HapticsManager.shared.lightImpact()
                            showingRightMenu = true
                            rightMenuOffset = 0
                            // タスク管理を確実に非表示
                            showingTaskManager = false
                            taskManagerOffset = 0
                        }
                    }
                } else {
                    // スワイプが不十分な場合は非表示
                    print("❌ Insufficient swipe, hiding both menus")
                    withAnimation(.easeOut(duration: 0.3)) {
                        HapticsManager.shared.lightImpact()
                        showingTaskManager = false
                        taskManagerOffset = 0
                        showingRightMenu = false
                        rightMenuOffset = 0
                    }
                }
                
                print("📊 After state - showingTaskManager: \(showingTaskManager), showingRightMenu: \(showingRightMenu)")
            }
    }
    
    // MARK: - Computed Properties for Landscape Control
    @ViewBuilder
    private var landscapeOverlay: some View {
        // 縦横置き時ともにオーバーレイを表示
        HStack {
            // 左側: タスク管理メニュー
            taskManagerOverlay
            
            Spacer()
            
            // 右側: 右側メニュー
            rightMenuOverlay
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

// MARK: - Task Manager Overlay
struct TaskManagerOverlay: View {
    @ObservedObject var taskManager: TaskManager
    @Binding var showingTaskManager: Bool
    @Binding var taskManagerOffset: CGFloat
    let onTaskSelected: (TaskItem, TaskCategory) -> Void
    
    @State private var selectedCategory: TaskCategory?
    @State private var selectedTask: TaskItem?
    @State private var showingAddTask = false
    @State private var showingEditTask = false
    @State private var taskToEdit: TaskItem?
    
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
                            taskManager: taskManager,
                            category: selectedCategory,
                            onTaskSelected: { task, category in
                                onTaskSelected(task, category)
                            },
                            onBackToCategories: {
                                self.selectedCategory = nil
                            },
                            onAddTask: {
                                showingAddTask = true
                            },
                            onEditTask: { task in
                                taskToEdit = task
                                showingEditTask = true
                            }
                        )
                    } else {
                        // カテゴリリストを動的に変更
                        VStack(spacing: 16) {
                            ForEach(taskManager.categories, id: \.id) { category in
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
                                    HapticsManager.shared.lightImpact()
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
        .sheet(isPresented: $showingAddTask) {
            if let selectedCategory = selectedCategory {
                AddTaskView(
                    taskManager: taskManager,
                    category: selectedCategory,
                    isPresented: $showingAddTask
                )
            }
        }
        .sheet(isPresented: $showingEditTask) {
            if let taskToEdit = taskToEdit, let selectedCategory = selectedCategory {
                EditTaskView(
                    taskManager: taskManager,
                    task: taskToEdit,
                    category: selectedCategory,
                    isPresented: $showingEditTask
                )
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
    @ObservedObject var taskManager: TaskManager
    let category: TaskCategory
    let onTaskSelected: (TaskItem, TaskCategory) -> Void
    let onBackToCategories: () -> Void
    let onAddTask: () -> Void
    let onEditTask: (TaskItem) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button and add button
            HStack {
                Button(action: {
                    onBackToCategories()
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
                
                Button(action: {
                    onAddTask()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignSystem.Colors.neonBlue)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Task list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(taskManager.categories.first(where: { $0.id == category.id })?.tasks ?? [], id: \.id) { task in
                        TaskCard(
                            task: task,
                            onTap: {
                                onTaskSelected(task, category)
                            },
                            onEdit: {
                                onEditTask(task)
                            },
                            onDelete: {
                                taskManager.deleteTask(task.id, from: category.id)
                            },
                            onToggleCompletion: {
                                taskManager.toggleTaskCompletion(task.id, in: category.id)
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
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    let onToggleCompletion: (() -> Void)?
    
    init(task: TaskItem, onTap: @escaping () -> Void, onEdit: (() -> Void)? = nil, onDelete: (() -> Void)? = nil, onToggleCompletion: (() -> Void)? = nil) {
        self.task = task
        self.onTap = onTap
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onToggleCompletion = onToggleCompletion
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 完了チェックボックス
            if let onToggleCompletion = onToggleCompletion {
                Button(action: onToggleCompletion) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // タスク情報
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.name)
                        .headlineStyle()
                        .primaryText()
                            .strikethrough(task.isCompleted)
                            .opacity(task.isCompleted ? 0.6 : 1.0)
                    
                    Text(task.description)
                        .subheadlineStyle()
                        .secondaryText()
                            .opacity(task.isCompleted ? 0.6 : 1.0)
                    
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
            }
            .buttonStyle(PlainButtonStyle())
            
            // 編集・削除ボタン
            if onEdit != nil || onDelete != nil {
                HStack(spacing: 8) {
                    if let onEdit = onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        .background(Color.white.opacity(task.isCompleted ? 0.02 : 0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
