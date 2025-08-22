import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Sound Playback
    func playChime() {
        guard let url = Bundle.main.url(forResource: "chime", withExtension: "wav") else {
            print("Chime sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play chime sound: \(error)")
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
