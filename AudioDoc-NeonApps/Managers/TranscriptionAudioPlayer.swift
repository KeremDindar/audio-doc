import UIKit
import AVFoundation

// MARK: - TranscriptionAudioPlayerDelegate
protocol TranscriptionAudioPlayerDelegate: AnyObject {
    func audioPlayerDidFinishPlaying()
    func audioPlayerDidUpdateTime()
}

class TranscriptionAudioPlayer: NSObject {
    // MARK: - Properties
    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL
    private var isPlaying = false
    private var updateTimer: Timer?
    
    weak var delegate: TranscriptionAudioPlayerDelegate?
    
    // MARK: - UI Components
    let timeSlider = UISlider()
    let currentTimeLabel = UILabel()
    let totalTimeLabel = UILabel()
    let playButton = UIButton()
    let speedButton = UIButton()
    
    // MARK: - Initialization
    init(audioURL: URL) {
        self.audioURL = audioURL
        super.init()
        setupAudioPlayer()
        setupUI()
    }
    
    // MARK: - Setup
    private func setupAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            // Setup time slider with duration
            if let duration = audioPlayer?.duration {
                timeSlider.minimumValue = 0
                timeSlider.maximumValue = Float(duration)
                totalTimeLabel.text = formatTime(duration)
            }
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func setupUI() {
        // Configure UI components
        timeSlider.minimumTrackTintColor = .systemBlue
        timeSlider.maximumTrackTintColor = .systemGray3
        timeSlider.setThumbImage(UIImage(systemName: "circle.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal), for: .normal)
        timeSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        timeSlider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        timeSlider.addTarget(self, action: #selector(sliderTouchUp), for: [.touchUpInside, .touchUpOutside])
        
        currentTimeLabel.text = "00:00"
        currentTimeLabel.font = .systemFont(ofSize: 12)
        currentTimeLabel.textColor = .darkGray
        currentTimeLabel.textAlignment = .left
        
        totalTimeLabel.text = "00:00"
        totalTimeLabel.font = .systemFont(ofSize: 12)
        totalTimeLabel.textColor = .darkGray
        totalTimeLabel.textAlignment = .right
        
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .darkGray
        
        speedButton.setTitle("1x", for: .normal)
        speedButton.tintColor = .darkGray
        speedButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateTimeLabels() {
        guard let player = audioPlayer else { return }
        currentTimeLabel.text = formatTime(player.currentTime)
        totalTimeLabel.text = formatTime(player.duration)
        delegate?.audioPlayerDidUpdateTime()
    }
    
    private func startTimeUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            
            if !player.isPlaying {
                self.updateTimer?.invalidate()
                return
            }
            
            self.timeSlider.value = Float(player.currentTime)
            self.updateTimeLabels()
        }
    }
    
    // MARK: - Public Methods
    func togglePlayPause() {
        guard let player = audioPlayer else { return }
        
        if isPlaying {
            player.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            updateTimer?.invalidate()
        } else {
            player.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            startTimeUpdateTimer()
        }
        
        isPlaying = !isPlaying
    }
    
    func skipBackward() {
        guard let player = audioPlayer else { return }
        let newTime = max(0, player.currentTime - 5)
        player.currentTime = newTime
        timeSlider.value = Float(newTime)
        updateTimeLabels()
    }
    
    func skipForward() {
        guard let player = audioPlayer else { return }
        let newTime = min(player.duration, player.currentTime + 5)
        player.currentTime = newTime
        timeSlider.value = Float(newTime)
        updateTimeLabels()
    }
    
    func changeSpeed() {
        guard let player = audioPlayer else { return }
        
        // Cycle through speed options: 1x -> 1.5x -> 2x -> 0.5x -> 1x
        switch player.rate {
        case 1.0:
            player.rate = 1.5
            speedButton.setTitle("1.5x", for: .normal)
        case 1.5:
            player.rate = 2.0
            speedButton.setTitle("2x", for: .normal)
        case 2.0:
            player.rate = 0.5
            speedButton.setTitle("0.5x", for: .normal)
        default:
            player.rate = 1.0
            speedButton.setTitle("1x", for: .normal)
        }
    }
    
    // MARK: - Actions
    @objc private func sliderValueChanged() {
        updateTimeLabels()
    }
    
    @objc private func sliderTouchDown() {
        audioPlayer?.pause()
    }
    
    @objc private func sliderTouchUp() {
        guard let player = audioPlayer else { return }
        player.currentTime = TimeInterval(timeSlider.value)
        
        if isPlaying {
            player.play()
        }
        
        updateTimeLabels()
    }
}

// MARK: - AVAudioPlayerDelegate
extension TranscriptionAudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        timeSlider.value = 0
        updateTimeLabels()
        delegate?.audioPlayerDidFinishPlaying()
    }
} 