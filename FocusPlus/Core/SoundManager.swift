import Foundation
import AVFoundation
import AudioToolbox

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    // MARK: - Sound Playback
    func playChime() {
        print("🔊 SoundManager: playChime() 呼び出され")
        
        // システムサウンド（SMSメッセージ受信音）を使用
        print("🔊 SMSメッセージ受信音を再生")
        AudioServicesPlaySystemSound(1007) // SMSメッセージ受信音
        
        // 音声セッションの設定（オプション）
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("✅ 音声セッションの設定が完了しました")
        } catch {
            print("⚠️ 音声セッションの設定に失敗しましたが、システムサウンドは再生されます: \(error)")
        }
    }
    
    func playSound(named fileName: String, withExtension ext: String = "wav") {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            print("Sound file not found: \(fileName).\(ext)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    // MARK: - Volume Control
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = max(0.0, min(1.0, volume))
    }
    
    // MARK: - Playback Control
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func pause() {
        audioPlayer?.pause()
    }
    
    func resume() {
        audioPlayer?.play()
    }
    
    // MARK: - Status
    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    var currentTime: TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    var duration: TimeInterval {
        return audioPlayer?.duration ?? 0
    }
}
