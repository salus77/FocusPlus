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
                // 横置きモード（縦並び）
                VStack(spacing: 20) {
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
            }
        }
    }
    
    private var buttonColor: Color {
        switch viewModel.state {
        case .finished:
            return .gray // Gray color when finished
        default:
            return .white
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch viewModel.state {
        case .finished:
            return Color.gray.opacity(0.3) // Gray background when finished
        case .running:
            return Color.orange // Orange for pause button
        default:
            return DesignSystem.Colors.neonBlue
        }
    }
}

#Preview {
    BottomControlsView(viewModel: TimerViewModel())
        .background(DesignSystem.Colors.background)
}
