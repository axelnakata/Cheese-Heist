import AVFoundation

final class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?
    private(set) var currentTrack: AudioTrack?

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Gagal konfigurasi Audio Session: \(error.localizedDescription)")
        }
    }

    func play(_ track: AudioTrack, loop: Bool = true) {
        // Jangan restart jika lagu yang minta diputar sama dengan yang sedang berjalan
        if currentTrack == track && player?.isPlaying == true { return }

        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else {
            print("File audio tidak ditemukan: \(track.fileName).\(track.fileExtension)")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = loop ? -1 : 0 // -1 untuk loop terus menerus
            player?.prepareToPlay()
            player?.play()
            currentTrack = track
        } catch {
            print("Gagal memutar audio: \(error.localizedDescription)")
        }
    }

    func stop() {
        player?.stop()
        currentTrack = nil
    }
}