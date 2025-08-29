import Foundation
import AVFoundation
import SwiftUI

// MARK: - Ambient Sound Types
enum AmbientSound: String, CaseIterable, Identifiable {
    case silent = "Silent"
    case tick = "Tick"
    case forest = "Forest"
    case raindrop = "Raindrop"
    case fire = "Fire"
    case wave = "Wave"
    case cafe = "Cafe"
    case storm = "Storm"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .silent: return "speaker.slash"
        case .tick: return "stopwatch"
        case .forest: return "tree.fill"
        case .raindrop: return "drop"
        case .fire: return "flame"
        case .wave: return "water.waves"
        case .cafe: return "cup.and.saucer"
        case .storm: return "cloud.bolt.rain"
        }
    }
    
    var isAvailable: Bool {
        // すべてのサウンドが利用可能
        return true
    }
    
    var displayName: String {
        switch self {
        case .silent: return "サイレント"
        case .tick: return "時計の音"
        case .forest: return "森の音"
        case .raindrop: return "雨音"
        case .fire: return "火の音"
        case .wave: return "波の音"
        case .cafe: return "カフェの音"
        case .storm: return "嵐の音"
        }
    }
    
    // MARK: - Sound File Names
    var soundFileName: String? {
        switch self {
        case .silent: return nil
        case .tick: return "tick"
        case .forest: return "forest"
        case .raindrop: return "raindrop"
        case .fire: return "fire"
        case .wave: return "wave"
        case .cafe: return "cafe"
        case .storm: return "storm"
        }
    }
    
    var soundFileExtension: String {
        // 実際のファイルはMP3形式
        return "mp3"
    }
}

// MARK: - Ambient Sound Manager
class AmbientSoundManager: ObservableObject {
    @Published var selectedSound: AmbientSound = .silent
    @Published var isPlaying: Bool = false
    @Published var volume: Float = 0.5
    
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    
    init() {
        loadSettings()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            // バックグラウンド再生のための設定
            let audioSession = AVAudioSession.sharedInstance()
            
            // 既存の設定を確認
            print("🔊 AmbientSoundManager: 現在の音声セッション設定:")
            print("  - Category: \(audioSession.category)")
            print("  - Mode: \(audioSession.mode)")
            print("  - Is Active: \(audioSession.isOtherAudioPlaying)")
            
            // 音声セッションを非アクティブにしてから再設定
            try audioSession.setActive(false)
            
            // カテゴリを設定（バックグラウンド再生を許可）
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP]
            )
            
            // セッションをアクティブ化
            try audioSession.setActive(true)
            
            // バックグラウンド再生の設定を確認
            if audioSession.category == .playback {
                print("✅ Audio session setup completed successfully")
                print("  - Category: \(audioSession.category.rawValue)")
                print("  - Mode: \(audioSession.mode.rawValue)")
                print("  - Options: \(audioSession.categoryOptions)")
            } else {
                print("⚠️ Audio session category not set to playback")
            }
        } catch {
            print("❌ Failed to setup audio session: \(error)")
            print("❌ エラーの詳細: \(error.localizedDescription)")
            
            // エラーの詳細情報を出力
            if let nsError = error as NSError? {
                print("❌ NSError詳細:")
                print("  - Domain: \(nsError.domain)")
                print("  - Code: \(nsError.code)")
                print("  - UserInfo: \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Sound Selection
    func selectSound(_ sound: AmbientSound) {
        print("🎵 AmbientSoundManager.selectSound() called")
        print("  - Previous Sound: \(selectedSound.displayName)")
        print("  - New Sound: \(sound.displayName)")
        
        let previousSound = selectedSound
        selectedSound = sound
        saveSettings()
        
        // サウンド変更時の制御
        if sound == .silent {
            // サイレントが選択された場合は音を停止
            print("  - 🔇 Silent selected - stopping sound")
            stopSound()
        } else if previousSound == .silent && sound != .silent {
            // サイレントから音のあるサウンドに変更された場合
            print("  - 🎵 Changed from silent to \(sound.displayName)")
            // 音の再生はContentViewのonChangeで制御される
        } else if previousSound != .silent && sound != .silent {
            // 音のあるサウンドから別の音のあるサウンドに変更された場合
            print("  - 🔄 Changed from \(previousSound.displayName) to \(sound.displayName)")
            if isPlaying {
                // 現在再生中なら新しいサウンドを再生
                stopSound()
                playSound()
            }
        }
    }
    
    // MARK: - Playback Control
    func playSound() {
        print("🎵 AmbientSoundManager.playSound() called")
        print("  - Selected Sound: \(selectedSound.displayName)")
        print("  - Current Volume: \(volume)")
        
        guard selectedSound != .silent else {
            print("  - ⚠️ Sound is silent, not playing")
            isPlaying = false
            return
        }
        
        // 現在のサウンドを停止
        stopSound()
        
        // バックグラウンド再生の設定を再確認
        setupAudioSession()
        
        // 新しいサウンドを再生
        if let soundURL = getSoundURL(for: selectedSound) {
            print("  - 📁 Sound file found: \(soundURL.lastPathComponent)")
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = volume
                audioPlayer?.numberOfLoops = -1 // 無限ループ
                
                // バックグラウンド再生の設定を強化
                audioPlayer?.prepareToPlay()
                
                // 再生開始
                if audioPlayer?.play() == true {
                    isPlaying = true
                    print("  - ✅ Successfully started playing: \(selectedSound.displayName)")
                    
                    // バックグラウンド再生の確認（より詳細）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if self.audioPlayer?.isPlaying == true {
                            print("  - ✅ Audio is playing in background")
                            print("  - 📱 Audio session active: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")
                            print("  - 🔊 Player volume: \(self.audioPlayer?.volume ?? 0)")
                        } else {
                            print("  - ⚠️ Audio may not be playing in background")
                        }
                    }
                } else {
                    print("  - ❌ Failed to start playing")
                    isPlaying = false
                }
            } catch {
                print("  - ❌ Failed to play sound: \(error)")
                isPlaying = false
                // フォールバック: システムサウンドを使用
                print("  - 🔄 Falling back to system sound...")
                playSystemSound()
            }
        } else {
            print("  - ⚠️ Sound file not found, using system sound")
            // サウンドファイルがない場合は、システムサウンドを使用
            playSystemSound()
        }
    }
    
    func stopSound() {
        print("🔇 AmbientSoundManager.stopSound() called")
        if let player = audioPlayer {
            print("  - Stopping AVAudioPlayer")
            player.stop()
        }
        audioPlayer = nil
        isPlaying = false
        print("  - ✅ Sound stopped")
    }
    
    func pauseSound() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    func resumeSound() {
        audioPlayer?.play()
        isPlaying = true
    }
    
    // MARK: - Volume Control
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
        audioPlayer?.volume = volume
        saveSettings()
    }
    
    // MARK: - Sound URL Management
    private func getSoundURL(for sound: AmbientSound) -> URL? {
        print("🔍 getSoundURL() called for: \(sound.displayName)")
        
        guard let fileName = sound.soundFileName else { 
            print("  - ⚠️ No filename for sound: \(sound.displayName)")
            return nil 
        }
        
        let fullFileName = "\(fileName).\(sound.soundFileExtension)"
        print("  - Looking for file: \(fullFileName)")
        
        // 1. まずBundle内のSoundsディレクトリを確認
        if let bundleURL = Bundle.main.url(forResource: fileName, withExtension: sound.soundFileExtension, subdirectory: "Sounds") {
            print("  - ✅ Found in Sounds subdirectory: \(bundleURL.path)")
            return bundleURL
        }
        
        // 2. Bundleのルートディレクトリを確認
        if let bundleURL = Bundle.main.url(forResource: fileName, withExtension: sound.soundFileExtension) {
            print("  - ✅ Found in bundle root: \(bundleURL.path)")
            return bundleURL
        }
        
        print("  - ❌ File not found: \(fullFileName)")
        print("  - Bundle path: \(Bundle.main.bundlePath)")
        
        // 利用可能なリソースを確認
        if let resourcePath = Bundle.main.resourcePath {
            print("  - Resource path: \(resourcePath)")
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("  - Available resources: \(contents)")
            } catch {
                print("  - Could not list resources: \(error)")
            }
        }
        
        return nil
    }
    
    // MARK: - System Sound Fallback
    private func playSystemSound() {
        // Apple公式推奨: システムサウンドは短い音声フィードバック用
        // 環境音には適していないため、タイマーで繰り返し再生
        switch selectedSound {
        case .tick:
            AudioServicesPlaySystemSound(1104) // メトロノーム風
        case .forest:
            AudioServicesPlaySystemSound(1103) // 自然音風
        case .raindrop:
            AudioServicesPlaySystemSound(1102) // 水の音風
        case .fire:
            AudioServicesPlaySystemSound(1101) // 火の音風
        case .wave:
            AudioServicesPlaySystemSound(1102) // 波の音風
        case .cafe:
            AudioServicesPlaySystemSound(1103) // カフェの音風
        case .storm:
            AudioServicesPlaySystemSound(1101) // 嵐の音風
        default:
            break
        }
        
        if selectedSound != .silent {
            isPlaying = true
            startSystemSoundTimer()
        }
    }
    
    private var systemSoundTimer: Timer?
    
    private func startSystemSoundTimer() {
        systemSoundTimer?.invalidate()
        
        let interval: TimeInterval
        switch selectedSound {
        case .tick: interval = 1.0
        case .forest: interval = 3.0
        case .raindrop: interval = 2.5
        case .fire: interval = 2.0
        case .wave: interval = 2.5
        case .cafe: interval = 3.0
        case .storm: interval = 2.0
        default: interval = 2.0
        }
        
        systemSoundTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else {
                self?.systemSoundTimer?.invalidate()
                return
            }
            self.playSystemSound()
        }
    }
    
    private func stopSystemSoundTimer() {
        systemSoundTimer?.invalidate()
        systemSoundTimer = nil
    }
    
    // MARK: - Settings Persistence
    private func saveSettings() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(selectedSound.rawValue, forKey: "selectedAmbientSound")
        userDefaults.set(volume, forKey: "ambientSoundVolume")
    }
    
    private func loadSettings() {
        let userDefaults = UserDefaults.standard
        if let soundRawValue = userDefaults.string(forKey: "selectedAmbientSound"),
           let sound = AmbientSound(rawValue: soundRawValue) {
            selectedSound = sound
        }
        volume = userDefaults.float(forKey: "ambientSoundVolume")
        if volume == 0 { volume = 0.5 } // デフォルト値
    }
    
    // MARK: - Cleanup
    deinit {
        stopSound()
        stopSystemSoundTimer()
    }
}

// MARK: - Audio Services Import
import AudioToolbox
