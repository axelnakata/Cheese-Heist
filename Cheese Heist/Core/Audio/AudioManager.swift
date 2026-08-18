//
//  AudioManager.swift
//  Cheese Heist
//
//  Created by Naila Lauza on 13/08/26.
//


import AVFoundation

final class AudioManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()
    
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?
    private var activeSFXPlayers: [AVAudioPlayer] = []
    private var loopingSFXPlayers: [AudioTrack: AVAudioPlayer] = [:]
    
    private var sfxPools: [AudioTrack: [AVAudioPlayer]] = [:]
    private var sfxPoolIndexes: [AudioTrack: Int] = [:]
    private let maxPoolSizePerTrack = 4
    
    private var onAudioFinished: (() -> Void)?
    
    // Properti Pengaturan Volume (0.0 sampai 1.0)
    var bgmVolume: Float = 0.35 {
        didSet { bgmPlayer?.volume = bgmVolume }
    }
    
    var sfxVolume: Float = 1.0 {
        didSet {
            sfxPlayer?.volume = sfxVolume
            for player in loopingSFXPlayers.values { player.volume = sfxVolume }
            for pool in sfxPools.values {
                for player in pool { player.volume = sfxVolume }
            }
        }
    }
    
    private(set) var currentBGMTrack: AudioTrack?

    private override init() {
        super.init()
        setupAudioSession()
        preloadJoystickSFX() // 🛠️ Preload otomatis saat AudioManager dibuat
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Gagal set up AVAudioSession: \(error)")
        }
    }
    
    // 🛠️ Fungsi Preload khusus untuk SFX joystick
    func preloadJoystickSFX() {
        preloadSFX(.gear1)
        preloadSFX(.gear2)
    }

    private func preloadSFX(_ track: AudioTrack) {
        guard sfxPools[track] == nil else { return }
        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else { return }
        
        var players: [AVAudioPlayer] = []
        for _ in 0..<maxPoolSizePerTrack {
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.volume = sfxVolume
                player.prepareToPlay()
                players.append(player)
            }
        }
        sfxPools[track] = players
        sfxPoolIndexes[track] = 0
    }

    // MARK: - Method BGM
    func playBGM(_ track: AudioTrack) {
        if currentBGMTrack == track && bgmPlayer?.isPlaying == true { return }

        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else { return }

        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.volume = bgmVolume
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()
            currentBGMTrack = track
        } catch {
            print("❌ Error BGM: \(error.localizedDescription)")
        }
    }

    // MARK: - Method SFX Rapid/Fast Playback
    func playSFX(_ track: AudioTrack) {
        if sfxPools[track] == nil {
            preloadSFX(track)
        }

        guard let pool = sfxPools[track], !pool.isEmpty else { return }
        
        let currentIndex = sfxPoolIndexes[track] ?? 0
        let player = pool[currentIndex]
        
        player.currentTime = 0
        player.volume = sfxVolume
        player.play()
        
        sfxPoolIndexes[track] = (currentIndex + 1) % pool.count
    }
   
    // MARK: - Method SFX Looping & Stopping
    func playLoopingSFX(_ track: AudioTrack) {
        if let existingPlayer = loopingSFXPlayers[track], existingPlayer.isPlaying { return }
        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = sfxVolume
            player.prepareToPlay()
            player.play()
            loopingSFXPlayers[track] = player
        } catch {
            print("❌ Gagal memutar Looping SFX: \(error.localizedDescription)")
        }
    }
        
    func stopSFX(_ track: AudioTrack) {
        if let player = loopingSFXPlayers[track] {
            player.stop()
            loopingSFXPlayers.removeValue(forKey: track)
        }
        
        if let pool = sfxPools[track] {
            for player in pool where player.isPlaying {
                player.stop()
            }
        }
    }
        
    func stopAllSFX() {
        activeSFXPlayers.forEach { $0.stop() }
        activeSFXPlayers.removeAll()
        
        loopingSFXPlayers.values.forEach { $0.stop() }
        loopingSFXPlayers.removeAll()
        
        for pool in sfxPools.values {
            pool.forEach { $0.stop() }
        }
    }

    // MARK: - Method SFX Sequential
    func playSFXAndWait(track: AudioTrack) async {
        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else { return }

        await withCheckedContinuation { continuation in
            do {
                sfxPlayer = try AVAudioPlayer(contentsOf: url)
                sfxPlayer?.delegate = self
                sfxPlayer?.volume = sfxVolume
                self.onAudioFinished = { continuation.resume() }
                sfxPlayer?.prepareToPlay()
                sfxPlayer?.play()
            } catch {
                continuation.resume()
            }
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let callback = onAudioFinished
        onAudioFinished = nil
        callback?()
    }

    // MARK: - BGM Fade
    
    // The BGM keeps playing through detection and role selection and only needs to get
    //    // OUT OF THE WAY while the child is cranking and while the win/lose SFX plays — so
    //    // this ramps the existing player's volume rather than stopping and restarting it,
    //    // which is what makes the return smooth instead of a hard cut back in.
    //
    //    /// Ramps the BGM down to silent. The player keeps running at zero volume rather than
    //    /// pausing, so `fadeInBGM` resumes in place instead of restarting the track.
    func fadeOutBGM(duration: TimeInterval = AppDuration.audioFade) {
        bgmPlayer?.setVolume(0, fadeDuration: duration)
    }

    /// Ramps the BGM back up to its configured volume.
    func fadeInBGM(duration: TimeInterval = AppDuration.audioFade) {
        bgmPlayer?.setVolume(bgmVolume, fadeDuration: duration)
    }
}
