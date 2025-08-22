import SwiftUI

struct EditTaskView: View {
    @ObservedObject var taskManager: TaskManager
    let task: TaskItem
    let category: TaskCategory
    @Binding var isPresented: Bool
    
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var estimatedMinutes: Int = 25
    @State private var selectedPriority: TaskPriority = .medium
    @State private var isCompleted: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("タスクを編集")
                        .largeTitleStyle()
                        .primaryText()
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(DesignSystem.Colors.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // タスク名
                        VStack(alignment: .leading, spacing: 8) {
                            Text("タスク名")
                                .headlineStyle()
                                .primaryText()
                            
                            TextField("タスク名を入力", text: $taskName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // 説明
                        VStack(alignment: .leading, spacing: 8) {
                            Text("説明")
                                .headlineStyle()
                                .primaryText()
                            
                            TextField("タスクの説明を入力", text: $taskDescription, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        // 予想時間
                        VStack(alignment: .leading, spacing: 8) {
                            Text("予想時間: \(estimatedMinutes)分")
                                .headlineStyle()
                                .primaryText()
                            
                            Slider(value: Binding(
                                get: { Double(estimatedMinutes) },
                                set: { estimatedMinutes = Int($0) }
                            ), in: 5...180, step: 5)
                                .accentColor(DesignSystem.Colors.neonBlue)
                        }
                        
                        // 優先度
                        VStack(alignment: .leading, spacing: 8) {
                            Text("優先度")
                                .headlineStyle()
                                .primaryText()
                            
                            Picker("優先度", selection: $selectedPriority) {
                                ForEach(TaskPriority.allCases, id: \.self) { priority in
                                    HStack {
                                        Image(systemName: "flag.fill")
                                            .foregroundColor(priority.color)
                                        Text(priority.rawValue)
                                    }
                                    .tag(priority)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // 完了状態
                        HStack {
                            Text("完了状態")
                                .headlineStyle()
                                .primaryText()
                            
                            Spacer()
                            
                            Toggle("", isOn: $isCompleted)
                                .labelsHidden()
                        }
                        
                        // 保存ボタン
                        Button(action: saveTask) {
                            Text("変更を保存")
                                .headlineStyle()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    canSaveTask ? DesignSystem.Colors.neonBlue : Color.gray
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!canSaveTask)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
            .background(DesignSystem.Colors.background)
        }
        .navigationBarHidden(true)
        .onAppear {
            loadTaskData()
        }
    }
    
    private var canSaveTask: Bool {
        !taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadTaskData() {
        taskName = task.name
        taskDescription = task.description
        estimatedMinutes = task.estimatedMinutes
        selectedPriority = task.priority
        isCompleted = task.isCompleted
    }
    
    private func saveTask() {
        var updatedTask = task
        updatedTask.name = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.description = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.estimatedMinutes = estimatedMinutes
        updatedTask.priority = selectedPriority
        updatedTask.isCompleted = isCompleted
        
        taskManager.updateTask(updatedTask, in: category.id)
        isPresented = false
    }
}

#Preview {
    EditTaskView(
        taskManager: TaskManager(),
        task: TaskItem(name: "サンプルタスク", description: "サンプルの説明", estimatedMinutes: 30, priority: .medium),
        category: TaskCategory(name: "仕事", icon: "briefcase.fill", color: .blue),
        isPresented: .constant(true)
    )
}
