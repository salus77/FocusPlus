import SwiftUI

struct AddCategoryView: View {
    @ObservedObject var taskManager: TaskManager
    @Binding var isPresented: Bool
    
    @State private var categoryName = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = Color.blue
    
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // カテゴリ名入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("カテゴリ名")
                        .headlineStyle()
                        .primaryText()
                    
                    TextField("例：仕事、勉強、趣味", text: $categoryName)
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
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .navigationTitle("カテゴリを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addCategory()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func addCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newCategory = TaskCategory(
            name: trimmedName,
            icon: selectedIcon,
            color: selectedColor,
            tasks: []
        )
        
        taskManager.addCategory(newCategory)
        isPresented = false
    }
}
