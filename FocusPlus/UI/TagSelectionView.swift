import SwiftUI

struct TagSelectionView: View {
    @ObservedObject var tagManager: TagManager
    @Binding var isPresented: Bool
    @State private var showingAddTag = false
    @State private var editingTag: Tag?
    
    let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(tagManager.tags) { tag in
                        TagItem(
                            tag: tag,
                            isSelected: tagManager.selectedTag?.id == tag.id,
                            onTap: {
                                tagManager.selectTag(tag)
                                // タグ選択後もシートは維持（完了ボタンで閉じる）
                            },
                            onLongPress: {
                                print("長押しが呼び出されました: \(tag.name)")
                                editingTag = tag
                                print("editingTagが設定されました: \(editingTag?.name ?? "nil")")
                            }
                        )
                    }
                    
                    // 「タグなし」オプション
                    TagItem(
                        tag: nil,
                        isSelected: tagManager.selectedTag == nil,
                        onTap: {
                            tagManager.selectTag(nil)
                            // タグなし選択後もシートは維持（完了ボタンで閉じる）
                        },
                        onLongPress: nil
                    )
                }
                .padding()
            }
            .navigationTitle("タグ選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTag = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTag) {
            TagEditView(
                tagManager: tagManager,
                isPresented: $showingAddTag,
                editingTag: nil
            )
        }
        .sheet(item: $editingTag) { tag in
            TagEditView(
                tagManager: tagManager,
                isPresented: Binding(
                    get: { editingTag != nil },
                    set: { if !$0 { editingTag = nil } }
                ),
                editingTag: tag
            )
            .onDisappear {
                editingTag = nil
            }
        }
        .onChange(of: editingTag) { newValue in
            print("editingTagが変更されました: \(newValue?.name ?? "nil")")
        }
    }
}

struct TagItem: View {
    let tag: Tag?
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                VStack(spacing: 8) {
                    Image(systemName: tag?.icon ?? "questionmark.circle")
                        .font(.system(size: 24))
                        .foregroundColor(tag?.color ?? .gray)
                    
                    Text(tag?.name ?? "タグなし")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                // 選択状態を示すチェックマーク
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(tag?.color ?? .gray)
                                .background(Color.white, in: Circle())
                        }
                        Spacer()
                    }
                    .padding(.top, 4)
                    .padding(.trailing, 4)
                }
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? (tag?.color ?? Color.gray).opacity(0.3) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? (tag?.color ?? Color.gray) : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5, maximumDistance: 50)
                                .onEnded { _ in
                                    print("長押しジェスチャーが検出されました: \(tag?.name ?? "タグなし")")
                                    onLongPress?()
                                }
                        )
    }
}

#Preview {
    TagSelectionView(
        tagManager: TagManager(),
        isPresented: .constant(true)
    )
}

