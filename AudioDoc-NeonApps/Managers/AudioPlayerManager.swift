import Foundation
import AVFoundation

protocol AudioPlayerManagerDelegate: AnyObject {
    // Bu fonksiyon, ses çaların mevcut zamanını (çalan süreyi) her güncellediğinde çağrılır.
    func audioPlayerManager(_ manager: AudioPlayerManager, didUpdateCurrentTime time: TimeInterval)
    
    //  Bu fonksiyon, ses çaların oynatma durumunu (çalıyor mu, duraklatıldı mı?) güncellediğinde çağrılır.
    func audioPlayerManager(_ manager: AudioPlayerManager, didUpdatePlaybackState isPlaying: Bool)
    
    //Bu fonksiyon, ses dosyası başarıyla tamamlandığında çağrılır.
    func audioPlayerManagerDidFinishPlaying(_ manager: AudioPlayerManager)
}

class AudioPlayerManager: NSObject {
    
    // MARK: - Properties
    
    // iOS'te ses dosyalarını çalmak için kullanılan bir sınıftır.
    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL
    
    //Sesin çalarken her 0.1 saniyede bir güncellenen bir zamanlayıcıdır. Bu zamanlayıcı, sesin ilerlemesini takip etmek için kullanılır.
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
            // Audio oturumunu alıyoruz (cihazın ses çalma yönetimi için)
            let audioSession = AVAudioSession.sharedInstance()
            
            // Ses kategorisini ayarlıyoruz: playback modu (arka planda çalma vb.)
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
            
            // Oturumu aktif hale getiriyoruz
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Verilen URL'den ses dosyasını player'a yüklüyoruz
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            
            // Delegate ataması yapılıyor (çalma bittiğinde vs. tetiklenmesi için)
            audioPlayer?.delegate = self
            
            // Ses ön yükleniyor (hazırlık yapılıyor)
            audioPlayer?.prepareToPlay()
            
            // Zamanlayıcı başlatılıyor (her 0.1 sn’de UI’yı güncellemek için)
            startUpdateTimer()
        } catch {
            // Hata durumunda log yazdırıyoruz
            print("Error setting up audio player: \(error.localizedDescription)")
        }
    }

    private func startUpdateTimer() {
        // Önce var olan timer varsa iptal ediliyor
        updateTimer?.invalidate()
        
        // Yeni bir timer başlatılıyor (her 0.1 saniyede bir çalışıyor)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Delegate'e mevcut süre bilgisi gönderiliyor
            self.delegate?.audioPlayerManager(self, didUpdateCurrentTime: self.currentTime)
        }
    }

    
    // MARK: - Playback Control
    func play() {
        audioPlayer?.play() // Ses oynatılıyor
        delegate?.audioPlayerManager(self, didUpdatePlaybackState: true) // Delegate'e "oynatılıyor" bilgisi gönderiliyor
    }
    
    func pause() {
        audioPlayer?.pause() // Ses duraklatılıyor
        delegate?.audioPlayerManager(self, didUpdatePlaybackState: false) // Delegate'e "durdu" bilgisi gönderiliyor
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
        seek(to: currentTime + seconds) // Mevcut zamanın üstüne ekleyerek ileri sarma
    }

    func skipBackward(seconds: TimeInterval = 5) {
        seek(to: currentTime - seconds) // Mevcut zamanın altına inerek geri sarma
    }

    
    // MARK: - Cleanup
    func cleanup() {
        updateTimer?.invalidate() // Timer iptal ediliyor
        updateTimer = nil
        
        audioPlayer?.stop() // Çalma durduruluyor
        audioPlayer = nil // Bellekten siliniyor
        
        do {
            try AVAudioSession.sharedInstance().setActive(false) // Ses oturumu devre dışı bırakılıyor
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
        player.currentTime = 0 // Çalma bittiğinde süre başa alınır
        delegate?.audioPlayerManagerDidFinishPlaying(self) // Delegate bilgilendirilir
    }
}

