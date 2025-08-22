import SwiftUI

struct AddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    let category: TaskCategory
    @Binding var isPresented: Bool
    
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var estimatedMinutes: Int = 25
    @State private var selectedPriority: TaskPriority = .medium
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("新しいタスク")
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
                        
                        // 追加ボタン
                        Button(action: addTask) {
                            Text("タスクを追加")
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
    }
    
    private var canSaveTask: Bool {
        !taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addTask() {
        let newTask = TaskItem(
            name: taskName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            estimatedMinutes: estimatedMinutes,
            priority: selectedPriority
        )
        
        taskManager.addTask(newTask, to: category.id)
        isPresented = false
    }
}

#Preview {
    AddTaskView(
        taskManager: TaskManager(),
        category: TaskCategory(name: "仕事", icon: "briefcase.fill", color: .blue),
        isPresented: .constant(true)
    )
}
