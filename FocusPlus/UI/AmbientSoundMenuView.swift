import SwiftUI

// MARK: - Ambient Sound Menu View
struct AmbientSoundMenuView: View {
    @ObservedObject var soundManager: AmbientSoundManager
    @Binding var isPresented: Bool
    
    // 7つのサウンド + サイレント = 8個を2行4列で表示
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
                    Text("環境音")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Sound Grid
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(AmbientSound.allCases) { sound in
                        AmbientSoundItem(
                            sound: sound,
                            isSelected: soundManager.selectedSound == sound,
                            onTap: {
                                soundManager.selectSound(sound)
                                HapticsManager.shared.lightImpact()
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Volume Control
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "speaker.wave.1")
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: Binding(
                                get: { Double(soundManager.volume) },
                                set: { soundManager.setVolume(Float($0)) }
                            ),
                            in: 0...1,
                            step: 0.1
                        )
                        .accentColor(DesignSystem.Colors.neonBlue)
                        
                        Image(systemName: "speaker.wave.3")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("音量: \(Int(soundManager.volume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(DesignSystem.Colors.background)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Ambient Sound Item
struct AmbientSoundItem: View {
    let sound: AmbientSound
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? DesignSystem.Colors.neonBlue.opacity(0.2) : Color.clear)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: sound.icon)
                        .font(.title2)
                        .foregroundColor(sound.isAvailable ? (isSelected ? DesignSystem.Colors.neonBlue : .primary) : .secondary)
                        .frame(width: 30, height: 30)
                }
                
                // Title
                Text(sound.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(sound.isAvailable ? (isSelected ? DesignSystem.Colors.neonBlue : .primary) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32)
            }
            .frame(width: 80, height: 100)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!sound.isAvailable)
        .opacity(sound.isAvailable ? 1.0 : 0.6)
    }
}

// MARK: - Preview
#Preview {
    AmbientSoundMenuView(
        soundManager: AmbientSoundManager(),
        isPresented: .constant(true)
    )
}
