import SwiftUI

struct TaskManagementView: View {
    @ObservedObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddCategory = false
    @State private var showingAddTask = false
    @State private var selectedCategory: TaskCategory?
    @State private var editingTask: TaskItem?
    @State private var editingCategory: TaskCategory?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                categoryManagementSection
                taskManagementSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 50)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("タスク管理")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(taskManager: taskManager, isPresented: $showingAddCategory)
        }
        .sheet(isPresented: $showingAddTask) {
            if let firstCategory = taskManager.categories.first {
                AddTaskView(taskManager: taskManager, category: firstCategory, isPresented: $showingAddTask)
            }
        }
        .sheet(item: $editingTask) { task in
            if let category = taskManager.categories.first(where: { $0.tasks.contains(where: { $0.id == task.id }) }) {
                EditTaskView(taskManager: taskManager, task: task, category: category, isPresented: .constant(true))
            }
        }
        .sheet(item: $editingCategory) { category in
            EditCategoryView(taskManager: taskManager, category: category, isPresented: .constant(true))
        }
    }
    
    private var categoryManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("カテゴリ管理")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showingAddCategory = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            if taskManager.categories.isEmpty {
                Text("カテゴリがありません")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(taskManager.categories, id: \.id) { category in
                        CategoryManagementRow(
                            category: category,
                            onEdit: {
                                editingCategory = category
                            }
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
    
    private var taskManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("タスク管理")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showingAddTask = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            if taskManager.categories.isEmpty {
                Text("カテゴリを先に作成してください")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(taskManager.categories, id: \.id) { category in
                        ForEach(category.tasks, id: \.id) { task in
                            TaskManagementRow(
                                task: task,
                                category: category,
                                onEdit: {
                                    editingTask = task
                                }
                            )
                        }
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

// MARK: - Category Management Row
struct CategoryManagementRow: View {
    let category: TaskCategory
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // カテゴリアイコン
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(category.color)
                .frame(width: 40, height: 40)
                .background(category.color.opacity(0.2))
                .clipShape(Circle())
            
            // カテゴリ情報
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(category.tasks.count)個のタスク")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 編集ボタンのみ
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Task Management Row
struct TaskManagementRow: View {
    let task: TaskItem
    let category: TaskCategory
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // タスク完了状態
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(task.isCompleted ? .green : .gray)
            
            // タスク情報
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .strikethrough(task.isCompleted)
                
                HStack(spacing: 12) {
                    Text(category.name)
                        .font(.caption)
                        .foregroundColor(category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(category.color.opacity(0.2))
                        .clipShape(Capsule())
                    
                    Text("\(task.estimatedMinutes)分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(task.priority.rawValue)
                        .font(.caption)
                        .foregroundColor(task.priority.color)
                }
            }
            
            Spacer()
            
            // 編集ボタンのみ
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Edit Category View
struct EditCategoryView: View {
    @ObservedObject var taskManager: TaskManager
    let category: TaskCategory
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName: String
    @State private var selectedIcon: String
    @State private var selectedColor: Color
    @State private var showingDeleteAlert = false
    
    private let availableIcons = [
        "folder.fill", "briefcase.fill", "book.fill", "graduationcap.fill",
        "house.fill", "car.fill", "gamecontroller.fill", "heart.fill",
        "star.fill", "leaf.fill", "flame.fill", "drop.fill",
        "bolt.fill", "sun.fill", "moon.fill", "cloud.fill"
    ]
    
    private let availableColors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink,
        .yellow, .mint, .teal, .indigo, .brown, .gray
    ]
    
    init(taskManager: TaskManager, category: TaskCategory, isPresented: Binding<Bool>) {
        self.taskManager = taskManager
        self.category = category
        self._isPresented = isPresented
        self._categoryName = State(initialValue: category.name)
        self._selectedIcon = State(initialValue: category.icon)
        self._selectedColor = State(initialValue: category.color)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // カテゴリ名入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("カテゴリ名")
                        .headlineStyle()
                        .primaryText()
                    
                    TextField("カテゴリ名", text: $categoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                // アイコン選択
                VStack(alignment: .leading, spacing: 16) {
                    Text("アイコン")
                        .headlineStyle()
                        .primaryText()
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : selectedColor)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? selectedColor : selectedColor.opacity(0.2))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(selectedIcon == icon ? selectedColor : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 色選択
                VStack(alignment: .leading, spacing: 16) {
                    Text("色")
                        .headlineStyle()
                        .primaryText()
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? .white : Color.clear, lineWidth: 3)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
                
                // 削除ボタン
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Text("カテゴリを削除")
                        .headlineStyle()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .navigationTitle("カテゴリを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateCategory()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .alert("カテゴリを削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                deleteCategory()
            }
        } message: {
            Text("このカテゴリを削除しますか？カテゴリ内のすべてのタスクも削除されます。この操作は取り消せません。")
        }
    }
    
    private func updateCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let updatedCategory = TaskCategory(
            name: trimmedName,
            icon: selectedIcon,
            color: selectedColor,
            tasks: category.tasks
        )
        
        taskManager.updateCategory(updatedCategory)
        dismiss()
    }
    
    private func deleteCategory() {
        taskManager.deleteCategory(category)
        dismiss()
    }
}
