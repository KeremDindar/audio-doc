import Foundation
import AVFoundation

protocol AudioPlayerManagerDelegate: AnyObject {
    func audioPlayerManager(_ manager: AudioPlayerManager, didUpdateCurrentTime time: TimeInterval)
    
    func audioPlayerManager(_ manager: AudioPlayerManager, didUpdatePlaybackState isPlaying: Bool)
    
    func audioPlayerManagerDidFinishPlaying(_ manager: AudioPlayerManager)
}

class AudioPlayerManager: NSObject {
    
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL
    
  
    private var updateTimer: Timer?
    
    weak var delegate: AudioPlayerManagerDelegate?
    
    var currentTime: TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    var duration: TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    var playbackRate: Float {
        get { return audioPlayer?.rate ?? 1.0 }
        set { audioPlayer?.rate = newValue }
    }
    
    // MARK: - Initialization
    init(audioURL: URL) {
        self.audioURL = audioURL
        super.init()
        setupAudioPlayer()
    }
    
    // MARK: - Setup
    private func setupAudioPlayer() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
            
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Verilen URL'den ses dosyasını player'a yüklüyoruz
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            
            audioPlayer?.delegate = self
            
            audioPlayer?.prepareToPlay()
            
            startUpdateTimer()
        } catch {
            print("Error setting up audio player: \(error.localizedDescription)")
        }
    }

    private func startUpdateTimer() {
        updateTimer?.invalidate()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.delegate?.audioPlayerManager(self, didUpdateCurrentTime: self.currentTime)
        }
    }

    
    // MARK: - Playback Control
    func play() {
        audioPlayer?.play()
        delegate?.audioPlayerManager(self, didUpdatePlaybackState: true)
    }
    
    func pause() {
        audioPlayer?.pause()
        delegate?.audioPlayerManager(self, didUpdatePlaybackState: false)
    }

    
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    //  Bu fonksiyon belirli bir zamana atlama işini yapar. Örneğin: 1:30 dakikaya git gibi.
    func seek(to time: TimeInterval) {
        // Verilen zaman değeri geçerli aralıkta mı kontrol ediliyor
        audioPlayer?.currentTime = max(0, min(time, duration))
    }
    
    func skipForward(seconds: TimeInterval = 5) {
        seek(to: currentTime + seconds)
    }

    func skipBackward(seconds: TimeInterval = 5) {
        seek(to: currentTime - seconds)
    }

    
    // MARK: - Cleanup
    func cleanup() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error.localizedDescription)")
        }
    }

    
    // MARK: - Helper Methods
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        player.currentTime = 0
        delegate?.audioPlayerManagerDidFinishPlaying(self) 
    }
}

