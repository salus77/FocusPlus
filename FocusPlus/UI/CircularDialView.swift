import SwiftUI

struct CircularDialView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showHint = true
    @State private var lastMinutes: Int = 0 // 振動トラッキング用
    @State private var previousAngle: Double = 0 // 前回の角度（移動方向判定用）
    @State private var isClockwise: Bool = true // 移動方向（時計回り/反時計回り）
    @State private var completionBlinkOpacity: Double = 1.0 // 完了時の点滅用
    
    private let minTime: TimeInterval = 1 * 60 // 1分
    private let maxTime: TimeInterval = 60 * 60 // 60分
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景の円（メイン円、実行中はより薄く）
                Circle()
                    .stroke(
                        Color.white.opacity(viewModel.state == .running ? 0.05 : 0.1), 
                        lineWidth: 2
                    )
                    .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                    .opacity(completionBlinkOpacity)
                
                // タイマー実行中の残像円（完全な円を薄く表示）
                if viewModel.state == .running {
                    Circle()
                        .trim(from: 0, to: 1)
                        .stroke(
                            viewModel.currentTaskCategoryColor.opacity(0.15),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                    .rotationEffect(.degrees(-90))
                        .opacity(completionBlinkOpacity)
                }
                
                // 外側の目盛り円（目盛りの基準円）
                Circle()
                    .stroke(Color.clear, lineWidth: 1)
                    .frame(width: geometry.size.width * 0.85, height: geometry.size.width * 0.85)
                
                // 分刻みの目盛り（円の外側に配置、タイマー停止中のみ表示）
                if viewModel.state != .running {
                ForEach(0..<60, id: \.self) { minute in
                    let angle = Double(minute) * 6.0 - 90.0 // 6度刻み（360度÷60分）
                    let isMajorTick = minute % 5 == 0 // 5分刻みで太い目盛り
                    
                    Rectangle()
                            .fill(Color.white.opacity(isMajorTick ? 0.8 : 0.4))
                        .frame(
                                width: isMajorTick ? 2 : 1,
                                height: isMajorTick ? 10 : 6
                        )
                            .offset(y: -geometry.size.width * 0.425) // 円の外側に配置
                        .rotationEffect(.degrees(angle))
                    }
                }
                
                // プログレス円（細いライン）
                Circle()
                    .trim(
                        from: 0,
                        to: viewModel.state == .running ? (1 - progress) : progress
                    )
                    .stroke(
                        viewModel.state == .finished ? Color.white : viewModel.currentTaskCategoryColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                    .rotationEffect(.degrees(-90))
                    .opacity(completionBlinkOpacity)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: progress)
                
                // 中央の時間表示
                VStack(spacing: 8) {
                                               if isDragging {
                               // ドラッグ中の時間表示（少し大きく）
                               Text(timeString(from: timeFromDrag()))
                                   .font(.system(size: 48, weight: .bold, design: .rounded))
                                   .foregroundColor(viewModel.currentTaskCategoryColor)
                                   .animation(.easeInOut(duration: 0.2), value: isDragging)
                           } else if viewModel.state == .running {
                               // タイマー実行中の時間表示（大きく）
                               Text(timeString(from: viewModel.timeRemaining))
                                   .font(.system(size: 52, weight: .bold, design: .rounded))
                                   .foregroundColor(viewModel.currentTaskCategoryColor)
                           } else {
                               // 通常の時間表示（停止中）
                               Text(timeString(from: viewModel.timeRemaining))
                                   .font(.system(size: 42, weight: .bold, design: .rounded))
                                   .foregroundColor(viewModel.currentTaskCategoryColor)
                           }
                    
                                               // フェーズ表示（文言を削除してよりミニマルに）
                           // Text(viewModel.phase == .focus ? "集中時間" : "")
                           //     .subheadlineStyle()
                           //     .foregroundColor(DesignSystem.Colors.neonBlue)
                    
                    // ヒント表示（タイマー停止中のみ）
                    if showHint && !isDragging && viewModel.state != .running {
                        Text("ドラッグで時間設定")
                            .font(.caption)
                            .foregroundColor(viewModel.currentTaskCategoryColor.opacity(0.7))
                            .opacity(showHint ? 1 : 0)
                            .animation(.easeInOut(duration: 0.3), value: showHint)
                    }
                }
                
                // ドラッグ可能な円（目盛りエリアを含む）
                Circle()
                    .fill(Color.clear)
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.9, height: min(geometry.size.width, geometry.size.height) * 0.9)
                    .contentShape(Circle())
                    .gesture(
                        // タイマーが実行中でない場合のみドラッグを有効化（idle, paused, finished状態で有効）
                        viewModel.state != .running ? 
                        DragGesture()
                            .onChanged { value in
                                print("🎯 ドラッグ開始 - 状態: \(viewModel.state)")
                                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                
                                if !isDragging {
                                    isDragging = true
                                    showHint = false
                                    // ドラッグ開始時の角度を記録
                                    previousAngle = angleFromPoint(value.location, center: center)
                                }
                                
                                // 現在のドラッグ位置の角度を計算
                                let dragAngle = angleFromPoint(value.location, center: center)
                                
                                // 移動方向を判定（時計回りか反時計回りか）
                                let currentAngle = dragAngle
                                let angleDelta = calculateAngleDelta(from: previousAngle, to: currentAngle)
                                isClockwise = angleDelta > 0
                                
                                // 前回の角度を更新
                                previousAngle = currentAngle
                                
                                // 角度から直接時間を計算（0度 = 0分、6度 = 1分、360度 = 60分）
                                let newTime = angleToTime(dragAngle)
                                
                                print("🔍 ドラッグ角度計算: 角度=\(String(format: "%.1f", dragAngle))°, 時間=\(newTime/60)分")
                                
                                // 時間を更新（totalTimeは最初の1回のみ）
                                if viewModel.totalTime == 0 {
                                    viewModel.totalTime = viewModel.timeRemaining
                                }
                                viewModel.timeRemaining = newTime
                                
                                // 1分刻みでの振動フィードバック
                                let currentMinutes = Int(viewModel.timeRemaining) / 60
                                if currentMinutes != lastMinutes {
                                    HapticsManager.shared.lightImpact()
                                    lastMinutes = currentMinutes
                                }
                            }
                            .onEnded { _ in
                                print("🎯 ドラッグ終了 - 最終時間: \(viewModel.timeRemaining/60)分")
                                isDragging = false
                                
                                // ドラッグ終了時の振動フィードバック
                                HapticsManager.shared.mediumImpact()
                                
                                // ドラッグ状態をリセット
                                previousAngle = 0
                                isClockwise = true
                                
                                // ヒントを少し遅れて表示
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    showHint = true
                                }
                            }
                        : nil
                    )
                    .onAppear {
                        print("🎯 CircularDialView onAppear - 現在の状態: \(viewModel.state)")
                    }
                    .onChange(of: viewModel.state) { _, newState in
                        print("🎯 タイマー状態変更: \(newState) - ドラッグ可能: \(newState != .running)")
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // 初期値を設定
            lastMinutes = Int(viewModel.timeRemaining) / 60
            
            // 初期値のプログレスバー位置を正しく設定
            // 25分の場合、25/60の位置（約150度）に表示されるようにする
            if viewModel.totalTime == 0 {
                viewModel.totalTime = viewModel.timeRemaining
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            print("🔄 状態変更: \(newState)")
            if newState == .finished {
                print("✅ タイマー完了検出: 点滅アニメーション開始")
                startCompletionBlink()
            }
        }
        }
    }
    
    private var progress: Double {
        // タイマー実行中は経過時間ベースで計算（360°から開始して短くなる）
        if viewModel.state == .running {
            guard viewModel.totalTime > 0 else { return 0 }
            
            // 経過時間の割合を計算
            let elapsedTime = viewModel.totalTime - viewModel.timeRemaining
            let progress = elapsedTime / viewModel.totalTime
            
            // デバッグログは無効化（必要に応じて有効化可能）
            #if DEBUG && false
            print("📊 実行中プログレス計算: 経過時間=\(elapsedTime/60)分, 総時間=\(viewModel.totalTime/60)分, プログレス=\(String(format: "%.3f", progress))")
            #endif
            
            return max(0, min(1, progress))
        } else {
            // 設定モード時は残り時間ベースで計算
            // 設定時間を角度に変換（0度=0分、6度=1分、360度=60分）
        let currentAngle = timeToAngle(viewModel.timeRemaining)
        
        // SwiftUIのCircle().trim()は3時方向（右）から時計回りに描画され、
        // .rotationEffect(.degrees(-90))で12時方向に回転させている
            // プログレスは0から1の範囲で、時計回りに増加する
        let progress = currentAngle / 360.0
        
            // デバッグログは無効化（必要に応じて有効化可能）
            #if DEBUG && false
            print("📊 設定モードプログレス計算: 時間=\(viewModel.timeRemaining/60)分, 角度=\(String(format: "%.1f", currentAngle))°, プログレス=\(String(format: "%.3f", progress))")
        #endif
        
        return max(0, min(1, progress))
        }
    }
    
    private func timeFromDrag() -> TimeInterval {
        return viewModel.timeRemaining
    }
    
    // MARK: - 円形ドラッグの王道ロジック
    
    /// 点から中心への角度を計算（0度 = 上/12時方向、90度 = 右/3時方向、時計回りが正）
    private func angleFromPoint(_ point: CGPoint, center: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        
        // Apple公式仕様に基づく角度計算
        // SwiftUIの座標系：原点(0,0)は左上、X軸右向き、Y軸下向き
        // 時計の角度：0度は上方向（12時方向）、90度は右方向（3時方向）、時計回りが正
        
        // 1. 数学的な角度を計算（atan2は-πからπの範囲）
        let mathAngle = atan2(dy, dx)
        
        // 2. 時計の角度に変換（上方向を0度、時計回りに正）
        // 指の動きとプログレスバーの方向を一致させるため、角度を調整
        let clockAngle = (mathAngle + .pi/2) * 180 / .pi
        
        // 3. 時計回りと反時計回りの両方で自然な境界処理を実現
        // 12時付近での境界を適切に処理
        var normalized = clockAngle
        
        // 角度を0-360度の範囲に正規化
        if normalized < 0 {
            normalized += 360
        }
        if normalized >= 360 {
            normalized -= 360
        }
        
        // 移動方向を考慮した境界処理
        // 境界かどうかに関係なく、全範囲で適用
        
        if isClockwise {
            // 時計回りの場合：60分（360度）で止まる
            if normalized >= 354 {
                normalized = 360
            }
        } else {
            // 反時計回りの場合：0分（0度）で止まる
            if normalized <= 0 {
                normalized = 0
            }
        }
        
        // デバッグログは無効化（必要に応じて有効化可能）
        #if DEBUG && false
        print("📍 角度計算:")
        print("  点(\(String(format: "%.1f", point.x)), \(String(format: "%.1f", point.y)))")
        print("  中心(\(String(format: "%.1f", center.x)), \(String(format: "%.1f", center.y)))")
        print("  dx=\(String(format: "%.1f", dx)), dy=\(String(format: "%.1f", dy))")
        print("  数学角度=\(String(format: "%.1f", mathAngle * 180 / .pi))°")
        print("  時計角度=\(String(format: "%.1f", clockAngle))°")
        print("  正規化=\(String(format: "%.1f", normalized))°")
        #endif
        
        return normalized
    }
    
    /// 2つの角度間の変化量を計算（時計回りを正の方向）
    private func calculateAngleDelta(from startAngle: Double, to endAngle: Double) -> Double {
        var delta = endAngle - startAngle
        
        // 角度の差が180度を超える場合、反対方向の方が近い
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }
        
        return delta
    }
    
    /// 時間（秒）を角度（度）に変換（1分刻み、12時方向から時計回り）
    private func timeToAngle(_ time: TimeInterval) -> Double {
        let minutes = time / 60.0
        let clampedMinutes = max(1, min(60, minutes))
        
        // Apple公式仕様に基づく角度計算
        // 12時方向（上）を0度として、時計回りに角度が増加
        // 1分 = 6度（360度 ÷ 60分）
        // 1分 = 6度、60分 = 360度
        let angle = clampedMinutes * 6.0
        
        // デバッグログは無効化（必要に応じて有効化可能）
        #if DEBUG && false
        print("⏰ 時間→角度: \(clampedMinutes)分 = \(String(format: "%.1f", angle))°")
        #endif
        
        return angle
    }
    
    /// 角度（度）を時間（分）に変換（1分刻み）
    private func angleToTime(_ angle: Double) -> TimeInterval {
        // Apple公式仕様に基づく角度計算
        // 0度 = 0分、6度 = 1分、360度 = 60分
        let minutes = angle / 6.0
        
        // 1分単位に丸める（四捨五入）
        let roundedMinutes = round(minutes)
        let clampedMinutes = max(1, min(60, roundedMinutes))
        let timeInSeconds = clampedMinutes * 60.0
        
        // デバッグログは無効化（必要に応じて有効化可能）
        #if DEBUG && false
        print("🔄 角度→時間: \(String(format: "%.1f", angle))° = \(minutes)分 → \(clampedMinutes)分 = \(timeInSeconds)秒")
        #endif
        
        return timeInSeconds
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 完了時の点滅アニメーションを開始
    private func startCompletionBlink() {
        print("🎬 点滅アニメーション開始: state = \(viewModel.state)")
        
        // プログレス円を白く点滅させるための状態
        completionBlinkOpacity = 1.0
        
        // 1回目の点滅（白く）
        withAnimation(.easeInOut(duration: 0.3)) {
            completionBlinkOpacity = 0.0
            print("🎬 点滅1回目: 透明化")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                completionBlinkOpacity = 1.0
                print("🎬 点滅1回目: 復元")
            }
            
            // 1回目の振動
            if self.viewModel.hapticsEnabled {
                HapticsManager.shared.heavyImpact()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // 2回目の点滅（白く）
                withAnimation(.easeInOut(duration: 0.3)) {
                    completionBlinkOpacity = 0.0
                    print("🎬 点滅2回目: 透明化")
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        completionBlinkOpacity = 1.0
                        print("🎬 点滅2回目: 復元完了")
                    }
                    
                    // 2回目の振動
                    if self.viewModel.hapticsEnabled {
                        HapticsManager.shared.heavyImpact()
                    }
                    
                    // 点滅完了後、BreakSheetView表示のためのコールバック
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.viewModel.onCompletionAnimationFinished()
                    }
                }
            }
        }
    }
}

#Preview {
    CircularDialView(viewModel: TimerViewModel())
        .background(DesignSystem.Colors.background)
}
