import SwiftUI

struct TagEditView: View {
    @ObservedObject var tagManager: TagManager
    @Binding var isPresented: Bool
    let editingTag: Tag?
    
    @State private var tagName: String = ""
    @State private var selectedIcon: String = "tag.fill"
    @State private var selectedColor: Color = .blue
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    @State private var showingDeleteAlert = false
    
    private var isEditing: Bool {
        editingTag != nil
    }
    
    private var isValidInput: Bool {
        !tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        tagManager.isTagNameValid(tagName, excluding: editingTag?.id)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("タグ名") {
                    TextField("タグ名を入力", text: $tagName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("アイコン") {
                    HStack {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundColor(selectedColor)
                            .frame(width: 30)
                        
                        Button("アイコンを選択") {
                            showingIconPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section("色") {
                    HStack {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 30, height: 30)
                        
                        Button("色を選択") {
                            showingColorPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                if isEditing {
                    Section {
                        Button("タグを削除") {
                            showingDeleteAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "タグを編集" : "タグを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTag()
                    }
                    .disabled(!isValidInput)
                }
            }
            .onAppear {
                setupInitialValues()
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon)
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor)
            }
            .alert("タグを削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteTag()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("このタグを削除しますか？削除されたタグは復元できません。")
            }
        }
    }
    
    private func setupInitialValues() {
        if let tag = editingTag {
            tagName = tag.name
            selectedIcon = tag.icon
            selectedColor = tag.color
        } else {
            tagName = ""
            selectedIcon = "tag.fill"
            selectedColor = .blue
        }
    }
    
    private func saveTag() {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let existingTag = editingTag {
            // 既存タグを更新
            tagManager.updateTag(existingTag, withName: trimmedName, icon: selectedIcon, color: selectedColor)
        } else {
            // 新しいタグを追加
            let newTag = Tag(
                name: trimmedName,
                icon: selectedIcon,
                color: selectedColor
            )
            tagManager.addTag(newTag)
        }
        
        isPresented = false
    }
    
    private func deleteTag() {
        guard let tag = editingTag else { return }
        tagManager.deleteTag(tag)
        isPresented = false
    }
}

// MARK: - Icon Picker View
struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    
    private let icons = [
        "tag", "tag.fill", "briefcase", "briefcase.fill", "folder", "folder.fill",
        "book", "book.fill", "book.closed", "paintpalette", "paintpalette.fill", "graduationcap",
        "person", "person.fill", "figure.run", "figure.hiking", "house", "house.fill",
        "star", "star.fill", "heart", "heart.fill", "leaf", "leaf.fill", "tree", "tree.fill",
        "cloud", "cloud.fill", "moon", "moon.fill", "drop", "drop.fill",
        "bolt", "bolt.fill", "snowflake",
        "umbrella", "airplane", "car", "car.fill", "bicycle", "tram", "bus",
        "gamecontroller", "gamecontroller.fill", "tv", "tv.fill",
        "laptopcomputer", "desktopcomputer", "iphone", "ipad", "applewatch", "headphones",
        "speaker", "speaker.fill", "music.note", "music.note.list", "camera", "camera.fill",
        "video", "video.fill", "photo", "photo.fill",
        "pencil", "pencil.circle", "pencil.circle.fill", "highlighter", "scissors", "paperclip",
        "link", "link.circle", "link.circle.fill",
        "gear", "gearshape", "gearshape.fill", "wrench", "wrench.fill", "hammer", "hammer.fill", "screwdriver", "screwdriver.fill"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // すべてのアイコンを一つのグリッドで表示
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                                dismiss()
                            }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                    .frame(width: 45, height: 45)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedIcon == icon ? Color.blue.opacity(0.1) : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    // デバッグ情報
                    print("=== アイコンデバッグ情報 ===")
                    print("総アイコン数: \(icons.count)")
                    print("アイコン一覧: \(icons)")
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("アイコンを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Color Picker View
struct ColorPickerView: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss
    
    private let allColors: [Color] = [
        .blue, .purple, .green, .orange, .red, .brown, .pink, .gray,
        .indigo, .teal, .mint, .cyan, .yellow
    ]
    
    var body: some View {
        NavigationView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                ForEach(allColors, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                        dismiss()
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 3)
                            )
                    }
                }
            }
            .padding()
            .navigationTitle("色を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TagEditView(
        tagManager: TagManager(),
        isPresented: .constant(true),
        editingTag: nil
    )
}
