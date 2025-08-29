import SwiftUI

struct BottomControlsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // 縦置きモード（横並び）
                HStack(spacing: 40) {
                    // リセットボタン
                    Button(action: {
                        viewModel.reset()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("リセット")
                    
                    // 開始/一時停止ボタン
                    Button(action: {
                        if viewModel.state == .running {
                            viewModel.pause()
                        } else {
                            viewModel.start()
                        }
                    }) {
                        Image(systemName: viewModel.state == .running ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(buttonColor)
                            .frame(width: 80, height: 80)
                            .background(buttonBackgroundColor)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(viewModel.currentTag?.color.opacity(0.3) ?? DesignSystem.Colors.neonBlue.opacity(0.3), lineWidth: 2)
                            )
                    }
                    .disabled(viewModel.state == .finished) // Disabled when finished
                    .accessibilityLabel(viewModel.state == .running ? "一時停止" : "開始")
                    
                    // スキップボタン
                    Button(action: {
                        viewModel.skip()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("スキップ")
                }
            } else {
                // 横置きモード（縦並び）- 「早送り」「再生」「リセット」の順
                VStack(spacing: 24) {
                    // スキップボタン（早送り）
                    Button(action: {
                        viewModel.skip()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("スキップ")
                    
                    // 開始/一時停止ボタン（再生）
                    Button(action: {
                        if viewModel.state == .running {
                            viewModel.pause()
                        } else {
                            viewModel.start()
                        }
                    }) {
                        Image(systemName: viewModel.state == .running ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(buttonColor)
                            .frame(width: 90, height: 90)
                            .background(buttonBackgroundColor)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(viewModel.currentTag?.color.opacity(0.3) ?? DesignSystem.Colors.neonBlue.opacity(0.3), lineWidth: 2)
                            )
                    }
                    .disabled(viewModel.state == .finished) // Disabled when finished
                    .accessibilityLabel(viewModel.state == .running ? "一時停止" : "開始")
                    
                    // リセットボタン
                    Button(action: {
                        viewModel.reset()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("リセット")
                }
            }
        }
    }
    
    private var buttonColor: Color {
        switch viewModel.state {
        case .finished:
            return .gray // Gray color when finished
        default:
            return viewModel.currentTag?.color ?? DesignSystem.Colors.neonBlue
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch viewModel.state {
        case .finished:
            return Color.gray.opacity(0.3) // Gray background when finished
        case .running:
            return (viewModel.currentTag?.color ?? DesignSystem.Colors.neonBlue).opacity(0.2) // タグ色の薄い背景
        default:
            return (viewModel.currentTag?.color ?? DesignSystem.Colors.neonBlue).opacity(0.3) // タグ色の背景
        }
    }
}

#Preview {
    BottomControlsView(viewModel: TimerViewModel())
        .background(DesignSystem.Colors.background)
}
