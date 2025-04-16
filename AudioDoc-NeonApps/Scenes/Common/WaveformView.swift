import UIKit

// MARK: - WaveformView

class WaveformView: UIView {
    // MARK: - Properties

    private var displayLink: CADisplayLink?
    
    // Dalga fazı
    private var phase: CGFloat = 0
    
    // Dalga frekansı
    private var frequency: CGFloat = 3.0
    
    // Dalga sayısı
    private var numberOfWaves: Int = 3
    
    // Mevcut ses seviyesi
    private var currentAudioLevel: Float = 0.2
    
    // Dalga stillendirme
    private let maxAmplitude: CGFloat = 30.0
    private let smoothingFactor: Float = 0.3
    private var previousAudioLevel: Float = 0.0
    
    // Dalga katmanı
    private let waveLayer = CAShapeLayer()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWaveform()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWaveform()
    }
    
    // MARK: - Setup
    // Dalga formunu ayarlama
    private func setupWaveform() {
        backgroundColor = .clear
        waveLayer.fillColor = UIColor.clear.cgColor
        waveLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.8).cgColor
        waveLayer.lineWidth = 3
        layer.addSublayer(waveLayer)
        
        // Boşta animasyonu başlat
        startIdleAnimation()
    }
    
    // MARK: - Public Methods
    // Ses seviyesini güncelleme
    func updateAudioLevel(_ level: Float) {
        // Ses seviyesini normalize et (0-1 aralığı)
        let normalizedLevel = min(max(level, 0), 1)
        
        // Seviyeyi artır ama makul bir aralıkta tut
        let enhancedLevel = normalizedLevel * 1.3
        let finalLevel = min(enhancedLevel, 1.0)
        
        // Yumuşatma uygula
        let smoothedLevel = (smoothingFactor * finalLevel) + ((1 - smoothingFactor) * previousAudioLevel)
        currentAudioLevel = smoothedLevel
        previousAudioLevel = smoothedLevel
        
        setNeedsDisplay()
    }
    
    // Boşta animasyonu başlat
    func startIdleAnimation() {
        currentAudioLevel = 0.2
        startAnimation()
    }
    
    // Animasyonu başlat
    func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateWaveform))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    // Animasyonu durdur
    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        phase = 0
        currentAudioLevel = 0
        setNeedsDisplay()
    }
    
    // MARK: - Drawing
    // Dalga formunu güncelle
    @objc private func updateWaveform() {
        phase += 0.03
        setNeedsDisplay()
    }
    
    // Dalga formunu çiz
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        let width = bounds.width
        let height = bounds.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        // Daha yumuşak dalga çiz
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            var y = midHeight
            
            for i in 0..<numberOfWaves {
                // Daha az dalgalı görünüm
                let frequency = self.frequency + CGFloat(i) * 0.35
                let amplitude = CGFloat(currentAudioLevel) * maxAmplitude 
                y += sin(relativeX * .pi * 2 * frequency + phase) * amplitude
            }
            
            // y'yi view sınırları içinde tut
            y = min(max(y, 0), height)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        waveLayer.path = path.cgPath
    }
} 
