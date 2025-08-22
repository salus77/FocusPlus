import SwiftUI

struct NeonProgressStyle: ProgressViewStyle {
    let color: Color
    let lineWidth: CGFloat
    
    init(color: Color = DesignSystem.Colors.neonBlue, lineWidth: CGFloat = 4) {
        self.color = color
        self.lineWidth = lineWidth
    }
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack {
                // 背景の円
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: lineWidth)
                
                // プログレス円
                Circle()
                    .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: configuration.fractionCompleted)
                
                // ネオン効果
                Circle()
                    .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                    .stroke(
                        color.opacity(0.6),
                        style: StrokeStyle(
                            lineWidth: lineWidth * 0.5,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 2)
                    .animation(.easeInOut(duration: 0.3), value: configuration.fractionCompleted)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Custom Progress View
struct NeonProgressView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(
        progress: Double,
        color: Color = DesignSystem.Colors.neonBlue,
        lineWidth: CGFloat = 4,
        size: CGFloat = 100
    ) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // 背景の円
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // プログレス円
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            // ネオン効果
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color.opacity(0.6),
                    style: StrokeStyle(
                        lineWidth: lineWidth * 0.5,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .blur(radius: 2)
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}

// MARK: - Progress View Extension
extension ProgressView {
    func neonStyle(color: Color = DesignSystem.Colors.neonBlue, lineWidth: CGFloat = 4) -> some View {
        self.progressViewStyle(NeonProgressStyle(color: color, lineWidth: lineWidth))
    }
}

#Preview {
    VStack(spacing: 40) {
        NeonProgressView(progress: 0.7, size: 120)
        
        ProgressView(value: 0.7)
            .neonStyle()
            .frame(width: 100, height: 100)
    }
    .padding()
    .background(DesignSystem.Colors.background)
}
