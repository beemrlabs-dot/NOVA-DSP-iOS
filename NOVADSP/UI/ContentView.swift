import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var dsp = DSPAudioEngine.shared
    @State private var showingImporter = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.045, blue: 0.065).ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        if selectedTab == 0 { equalizerPage }
                        else if selectedTab == 1 { presetsPage }
                        else { playerPage }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 30)
                }
                tabBar
            }
        }
        .preferredColorScheme(.dark)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav, .aiff], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                do { try dsp.loadAudio(from: url) } catch { print("Could not load audio: \(error)") }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 11).fill(Color.cyan.opacity(0.14)).frame(width: 38, height: 38)
                Image(systemName: "waveform.path").font(.system(size: 19, weight: .semibold)).foregroundStyle(.cyan)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("NOVA").font(.system(size: 17, weight: .black, design: .rounded)).tracking(2.2)
                Text("DIGITAL SOUND PROCESSOR").font(.system(size: 8, weight: .bold)).tracking(1.4).foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Circle().fill(Color.green).frame(width: 7, height: 7)
            Text("DSP ACTIVE").font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(.green)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(Color.white.opacity(0.025))
    }

    private var equalizerPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            titleBlock("Equalizer", subtitle: "10-BAND GRAPHIC EQUALIZER")
            HStack {
                Text(dsp.activePreset.uppercased()).font(.system(size: 10, weight: .bold)).tracking(1.3).foregroundStyle(.cyan)
                Spacer()
                Button("RESET") { dsp.applyPreset(EQPreset.all[0]) }
                    .font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.6))
            }
            VStack(spacing: 12) {
                HStack(alignment: .center, spacing: 0) {
                    ForEach(dsp.frequencies.indices, id: \.self) { index in
                        VStack(spacing: 8) {
                            Text(String(format: "%+.0f", dsp.gains[index]))
                                .font(.system(size: 9, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(dsp.gains[index] == 0 ? .white.opacity(0.38) : .cyan)
                            Slider(value: Binding(get: { Double(dsp.gains[index]) }, set: { dsp.setGain(Float($0), at: index) }), in: -12...12, step: 0.5)
                                .tint(.cyan)
                                .rotationEffect(.degrees(-90))
                                .frame(width: 112, height: 28)
                                .fixedSize()
                            Text(freqLabel(dsp.frequencies[index]))
                                .font(.system(size: 8, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 164)
                HStack {
                    Text("-12 dB"); Spacer(); Text("0 dB"); Spacer(); Text("+12 dB")
                }.font(.system(size: 8, weight: .medium)).foregroundStyle(.white.opacity(0.35))
            }
            .padding(14).background(panel).clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 10) {
                HStack { Text("OUTPUT PREAMP"); Spacer(); Text(String(format: "%+.1f dB", dsp.preamp)).foregroundStyle(.cyan) }
                    .font(.system(size: 10, weight: .bold)).tracking(1)
                Slider(value: Binding(get: { Double(dsp.preamp) }, set: { dsp.preamp = Float($0) }), in: -12...6, step: 0.5).tint(.cyan)
            }.padding(16).background(panel).clipShape(RoundedRectangle(cornerRadius: 16))

            titleBlock("Quick profiles", subtitle: "TAP TO APPLY A SOUND")
            presetChips
            playerStrip
        }
    }

    private var presetsPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            titleBlock("Sound profiles", subtitle: "TUNED FOR THE WAY YOU LISTEN")
            ForEach(EQPreset.all) { preset in
                Button { dsp.applyPreset(preset) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: presetIcon(preset.name)).font(.system(size: 18)).foregroundStyle(.cyan).frame(width: 42, height: 42).background(Color.cyan.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                            Text(preset.subtitle).font(.system(size: 11)).foregroundStyle(.white.opacity(0.45))
                        }
                        Spacer()
                        if dsp.activePreset == preset.name { Image(systemName: "checkmark.circle.fill").foregroundStyle(.cyan) }
                        else { Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.25)) }
                    }.padding(13).background(panel).clipShape(RoundedRectangle(cornerRadius: 15))
                }.buttonStyle(.plain)
            }
            playerStrip
        }
    }

    private var playerPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            titleBlock("Audio player", subtitle: "PLAY AUDIO THROUGH NOVA DSP")
            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [Color.cyan.opacity(0.20), Color.blue.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(height: 210)
                    Image(systemName: "waveform").font(.system(size: 70, weight: .ultraLight)).foregroundStyle(.cyan.opacity(0.8))
                }
                Text(dsp.loadedTrackName ?? "No track selected").font(.system(size: 16, weight: .semibold)).lineLimit(1)
                Text("Choose an audio file to process it with your NOVA EQ settings.").font(.system(size: 11)).foregroundStyle(.white.opacity(0.45)).multilineTextAlignment(.center)
                Button { showingImporter = true } label: { Label("CHOOSE AUDIO FILE", systemImage: "plus") }.buttonStyle(NovaButtonStyle())
                playbackControls
            }.padding(18).background(panel).clipShape(RoundedRectangle(cornerRadius: 22))
            titleBlock("Active profile", subtitle: "YOUR CURRENT SOUND")
            HStack { Text(dsp.activePreset).font(.system(size: 15, weight: .semibold)); Spacer(); Button("EDIT EQ") { selectedTab = 0 }.foregroundStyle(.cyan).font(.system(size: 10, weight: .bold)) }
                .padding(16).background(panel).clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }

    private var presetChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(EQPreset.all) { preset in
                    Button { dsp.applyPreset(preset) } label: {
                        Text(preset.name).font(.system(size: 10, weight: .semibold)).padding(.horizontal, 14).padding(.vertical, 10)
                            .background(dsp.activePreset == preset.name ? Color.cyan.opacity(0.18) : Color.white.opacity(0.055))
                            .foregroundStyle(dsp.activePreset == preset.name ? .cyan : .white.opacity(0.7))
                            .clipShape(Capsule()).overlay(Capsule().stroke(dsp.activePreset == preset.name ? Color.cyan.opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var playerStrip: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill").font(.system(size: 32)).foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 3) {
                Text(dsp.loadedTrackName ?? "NOVA Audio Player").font(.system(size: 11, weight: .semibold)).lineLimit(1)
                Text(dsp.isPlaying ? "PLAYING THROUGH DSP" : "READY TO PLAY").font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Button { dsp.togglePlayback() } label: { Image(systemName: dsp.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 15)).foregroundStyle(.black).frame(width: 38, height: 38).background(Color.cyan).clipShape(Circle()) }
            Button { showingImporter = true } label: { Image(systemName: "plus").foregroundStyle(.white).frame(width: 34, height: 34).background(Color.white.opacity(0.08)).clipShape(Circle()) }
        }.padding(13).background(panel).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var playbackControls: some View {
        VStack(spacing: 12) {
            HStack { Text(timeString(dsp.currentTime)); Spacer(); Text(timeString(dsp.duration)) }.font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.5))
            ProgressView(value: dsp.duration > 0 ? min(1, dsp.currentTime / dsp.duration) : 0).tint(.cyan)
            HStack(spacing: 32) {
                Button { dsp.stop() } label: { Image(systemName: "stop.fill").font(.system(size: 18)).foregroundStyle(.white.opacity(0.65)) }
                Button { dsp.togglePlayback() } label: { Image(systemName: dsp.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 22)).foregroundStyle(.black).frame(width: 58, height: 58).background(Color.cyan).clipShape(Circle()) }
                Button { showingImporter = true } label: { Image(systemName: "music.note.list").font(.system(size: 18)).foregroundStyle(.white.opacity(0.65)) }
            }.padding(.top, 6)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton("slider.horizontal.3", "EQUALIZER", 0)
            tabButton("square.grid.2x2", "PROFILES", 1)
            tabButton("music.note", "PLAYER", 2)
        }.padding(.top, 12).padding(.bottom, 8).background(Color.black.opacity(0.35))
    }
    private func tabButton(_ icon: String, _ title: String, _ index: Int) -> some View {
        Button { selectedTab = index } label: {
            VStack(spacing: 5) { Image(systemName: icon).font(.system(size: 17)); Text(title).font(.system(size: 8, weight: .bold)).tracking(0.8) }
                .foregroundStyle(selectedTab == index ? .cyan : .white.opacity(0.35)).frame(maxWidth: .infinity)
        }.buttonStyle(.plain)
    }
    private func titleBlock(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(subtitle).font(.system(size: 9, weight: .bold)).tracking(1.5).foregroundStyle(.white.opacity(0.38))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private var panel: some ShapeStyle { Color(red: 0.075, green: 0.09, blue: 0.12) }
    private func freqLabel(_ f: Float) -> String { f >= 1000 ? "\(Int(f / 1000))k" : "\(Int(f))" }
    private func timeString(_ value: TimeInterval) -> String { guard value.isFinite else { return "0:00" }; return String(format: "%d:%02d", Int(value) / 60, Int(value) % 60) }
    private func presetIcon(_ name: String) -> String {
        switch name { case "Bass Boost": return "speaker.wave.3.fill"; case "Vocal": return "mic.fill"; case "Rock": return "guitars.fill"; case "Pop": return "sparkles"; case "Jazz": return "pianokeys"; case "Classical": return "music.note"; case "Night Drive": return "moon.stars.fill"; default: return "waveform" }
    }
}

struct NovaButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 11, weight: .bold)).tracking(1).foregroundStyle(.black)
            .padding(.horizontal, 20).padding(.vertical, 14).frame(maxWidth: .infinity)
            .background(Color.cyan.opacity(configuration.isPressed ? 0.7 : 1)).clipShape(RoundedRectangle(cornerRadius: 13))
    }
}
