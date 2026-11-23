import AVFoundation
import Combine
import Foundation

@MainActor
final class DSPAudioEngine: ObservableObject {
    static let shared = DSPAudioEngine()

    @Published private(set) var isPlaying = false
    @Published private(set) var loadedTrackName: String?
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var preamp: Float = 0 { didSet { applyPreamp() } }
    @Published var gains: [Float] = Array(repeating: 0, count: 10) { didSet { applyEQ() } }
    @Published var activePreset = "Flat"

    let frequencies: [Float] = [31, 62, 125, 250, 500, 1_000, 2_000, 4_000, 8_000, 16_000]
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let equalizer: AVAudioUnitEQ
    private var audioFile: AVAudioFile?
    private var securityScopedURL: URL?
    private var timer: AnyCancellable?

    private init() {
        equalizer = AVAudioUnitEQ(numberOfBands: 10)
        for (index, band) in equalizer.bands.enumerated() {
            band.filterType = .parametric
            band.frequency = frequencies[index]
            band.bandwidth = 1.0
            band.gain = 0
            band.bypass = false
        }
        engine.attach(player)
        engine.attach(equalizer)
        engine.connect(player, to: equalizer, format: nil)
        engine.connect(equalizer, to: engine.mainMixerNode, format: nil)
        configureSession()
        do { try engine.start() } catch { print("NOVA DSP audio engine failed: \(error)") }
        startProgressTimer()
    }

    private func configureSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch { print("NOVA DSP audio session failed: \(error)") }
    }

    func loadAudio(from url: URL) throws {
        if let previousURL = securityScopedURL { previousURL.stopAccessingSecurityScopedResource() }
        let access = url.startAccessingSecurityScopedResource()
        do {
            let file = try AVAudioFile(forReading: url)
            player.stop()
            audioFile = file
            securityScopedURL = access ? url : nil
        } catch {
            if access { url.stopAccessingSecurityScopedResource() }
            throw error
        }
        duration = Double(file.length) / file.processingFormat.sampleRate
        currentTime = 0
        loadedTrackName = url.deletingPathExtension().lastPathComponent
        isPlaying = false
    }

    func play() {
        guard let file = audioFile else { return }
        if !engine.isRunning { do { try engine.start() } catch { return } }
        if !player.isPlaying {
            if currentTime == 0 || currentTime >= duration {
                player.stop()
                player.scheduleFile(file, at: nil)
            }
            player.play()
            isPlaying = true
        }
    }

    func pause() { player.pause(); isPlaying = false }
    func togglePlayback() { isPlaying ? pause() : play() }

    func stop() {
        player.stop()
        isPlaying = false
        currentTime = 0
    }

    func setGain(_ value: Float, at index: Int) {
        guard gains.indices.contains(index) else { return }
        var updated = gains
        updated[index] = min(12, max(-12, value))
        gains = updated
    }

    func applyPreset(_ preset: EQPreset) {
        activePreset = preset.name
        gains = preset.gains
        preamp = preset.preamp
    }

    private func applyEQ() {
        for index in equalizer.bands.indices where gains.indices.contains(index) {
            equalizer.bands[index].gain = gains[index]
        }
    }

    private func applyPreamp() {
        equalizer.globalGain = preamp
    }

    private func startProgressTimer() {
        timer = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isPlaying else { return }
                let nodeTime = self.player.lastRenderTime
                if let nodeTime, let playerTime = self.player.playerTime(forNodeTime: nodeTime) {
                    self.currentTime = Double(playerTime.sampleTime) / playerTime.sampleRate
                }
                if self.currentTime >= self.duration && self.duration > 0 { self.isPlaying = false }
            }
    }
}

struct EQPreset: Identifiable, Hashable {
    let name: String
    let subtitle: String
    let gains: [Float]
    var preamp: Float = 0
    var id: String { name }

    static let all: [EQPreset] = [
        .init(name: "Flat", subtitle: "Neutral reference", gains: [0,0,0,0,0,0,0,0,0,0]),
        .init(name: "Bass Boost", subtitle: "Deeper low end", gains: [5,7,6,3,0,-1,-1,0,1,1], preamp: -2),
        .init(name: "Vocal", subtitle: "Clearer voices", gains: [-2,-1,0,1,3,4,3,1,0,-1]),
        .init(name: "Rock", subtitle: "Punch and presence", gains: [4,3,-1,-2,0,2,4,5,4,4], preamp: -2),
        .init(name: "Pop", subtitle: "Polished everyday sound", gains: [-1,1,3,4,2,0,1,2,3,2]),
        .init(name: "Jazz", subtitle: "Warm and detailed", gains: [3,2,1,1,-1,-1,0,1,2,3]),
        .init(name: "Classical", subtitle: "Open and balanced", gains: [4,3,2,1,-1,-1,0,2,3,4]),
        .init(name: "Night Drive", subtitle: "Smooth, relaxed listening", gains: [2,2,1,0,1,1,0,-1,-2,-2])
    ]
}
