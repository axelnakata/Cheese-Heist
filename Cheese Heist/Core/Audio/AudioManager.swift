//
//  AudioManager.swift
//  Cheese Heist
//
//  Created by Naila Lauza on 13/08/26.
//


//import AVFoundation
//
//final class AudioManager: NSObject, AVAudioPlayerDelegate {
//    static let shared = AudioManager()
//    
//    private var bgmPlayer: AVAudioPlayer?
//    private var sfxPlayer: AVAudioPlayer?
//    private var onAudioFinished: (() -> Void)?
//    
//    private(set) var currentBGMTrack: AudioTrack?
//
//    private override init() {
//        super.init()
//        setupAudioSession()
//    }
//    
//    private func setupAudioSession() {
//        do {
//            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
//            try AVAudioSession.sharedInstance().setActive(true)
//        } catch {
//            print("❌ Gagal set up AVAudioSession: \(error)")
//        }
//    }
//
//    // MARK: - Method BGM (Looping, mendukung .mp3 dan .wav)
//    func playBGM(_ track: AudioTrack) {
//        if currentBGMTrack == track && bgmPlayer?.isPlaying == true {
//            return
//        }
//
//        // Membaca fileName dan fileExtension otomatis dari enum AudioTrack
//        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else {
//            print("❌ File BGM tidak ditemukan di Bundle: '\(track.fileName).\(track.fileExtension)'")
//            return
//        }
//
//        do {
//            bgmPlayer = try AVAudioPlayer(contentsOf: url)
//            bgmPlayer?.numberOfLoops = -1 // Loop selamanya
//            bgmPlayer?.volume = 1.0
//            bgmPlayer?.prepareToPlay()
//            
//            if bgmPlayer?.play() == true {
//                print("🔊 Memutar BGM: \(track.fileName).\(track.fileExtension)")
//                currentBGMTrack = track
//            }
//        } catch {
//            print("❌ Error AVAudioPlayer BGM: \(error.localizedDescription)")
//        }
//    }
//
//    func stopBGM() {
//        bgmPlayer?.stop()
//        currentBGMTrack = nil
//    }
//
//    // MARK: - Method SFX (Sequential Playback, mendukung .mp3 dan .wav)
//    func playSFXAndWait(track: AudioTrack) async {
//        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else {
//            print("❌ File SFX tidak ditemukan di Bundle: '\(track.fileName).\(track.fileExtension)'")
//            return
//        }
//
//        await withCheckedContinuation { continuation in
//            do {
//                sfxPlayer = try AVAudioPlayer(contentsOf: url)
//                sfxPlayer?.delegate = self
//              
//                self.onAudioFinished = {
//                    continuation.resume()
//                }
//                
//                sfxPlayer?.prepareToPlay()
//                sfxPlayer?.play()
//                print("🔊 Memutar SFX: \(track.fileName).\(track.fileExtension)")
//            } catch {
//                print("❌ Gagal memutar SFX: \(error.localizedDescription)")
//                continuation.resume()
//            }
//        }
//    }
//
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        let callback = onAudioFinished
//        onAudioFinished = nil
//        callback?()
//    }
//    
//    // MARK: - Method SFX Instant (Cocok untuk Tap / Button Click)
//    func playSFX(_ track: AudioTrack) {
//        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else {
//            print("❌ File SFX tidak ditemukan: '\(track.fileName).\(track.fileExtension)'")
//            return
//        }
//
//        do {
//            sfxPlayer = try AVAudioPlayer(contentsOf: url)
//            sfxPlayer?.volume = 1.0
//            sfxPlayer?.prepareToPlay()
//            sfxPlayer?.play()
//        } catch {
//            print("❌ Gagal memutar SFX Tap: \(error.localizedDescription)")
//        }
//    }   
//}

import AVFoundation

final class AudioManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()
    
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?
    private var activeSFXPlayers: [AVAudioPlayer] = []
    private var onAudioFinished: (() -> Void)?
    
    // Properti Pengaturan Volume (0.0 sampai 1.0)
    var bgmVolume: Float = 0.35 { // Set default BGM lebih kecil agar SFX jelas
        didSet {
            bgmPlayer?.volume = bgmVolume
        }
    }
    
    var sfxVolume: Float = 1.0 {
        didSet {
            sfxPlayer?.volume = sfxVolume
        }
    }
    
    private(set) var currentBGMTrack: AudioTrack?

    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Gagal set up AVAudioSession: \(error)")
        }
    }

    // MARK: - Method BGM (Dengan pengaturan volume BGM yang lebih lembut)
    func playBGM(_ track: AudioTrack) {
        if currentBGMTrack == track && bgmPlayer?.isPlaying == true { return }

        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else {
            print("❌ File BGM tidak ditemukan: '\(track.fileName).\(track.fileExtension)'")
            return
        }

        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.volume = bgmVolume // <--- Terapkan bgmVolume (0.35)
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()
            currentBGMTrack = track
        } catch {
            print("❌ Error AVAudioPlayer BGM: \(error.localizedDescription)")
        }
    }

    // MARK: - Method SFX Instant (Memutar SFX dengan volume kencang)
    func playSFX(_ track: AudioTrack) {
        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else {
            print("❌ File SFX tidak ditemukan: '\(track.fileName).\(track.fileExtension)'")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = sfxVolume // <--- Terapkan sfxVolume (1.0)
            player.prepareToPlay()
            player.play()
            
            activeSFXPlayers.append(player)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) { [weak self] in
                self?.activeSFXPlayers.removeAll { $0 == player }
            }
        } catch {
            print("❌ Gagal memutar SFX: \(error.localizedDescription)")
        }
    }

    // MARK: - Method SFX Sequential (Untuk Bintang / Success)
    func playSFXAndWait(track: AudioTrack) async {
        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else {
            print("❌ File SFX tidak ditemukan: '\(track.fileName).\(track.fileExtension)'")
            return
        }

        await withCheckedContinuation { continuation in
            do {
                sfxPlayer = try AVAudioPlayer(contentsOf: url)
                sfxPlayer?.delegate = self
                sfxPlayer?.volume = sfxVolume
                self.onAudioFinished = { continuation.resume() }
                sfxPlayer?.prepareToPlay()
                sfxPlayer?.play()
            } catch {
                print("❌ Gagal memutar SFX: \(error.localizedDescription)")
                continuation.resume()
            }
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let callback = onAudioFinished
        onAudioFinished = nil
        callback?()
    }

    // MARK: - BGM fade
    //
    // The BGM keeps playing through detection and role selection and only needs to get
    // OUT OF THE WAY while the child is cranking and while the win/lose SFX plays — so
    // this ramps the existing player's volume rather than stopping and restarting it,
    // which is what makes the return smooth instead of a hard cut back in.

    /// Ramps the BGM down to silent. The player keeps running at zero volume rather than
    /// pausing, so `fadeInBGM` resumes in place instead of restarting the track.
    func fadeOutBGM(duration: TimeInterval = AppDuration.audioFade) {
        bgmPlayer?.setVolume(0, fadeDuration: duration)
    }

    /// Ramps the BGM back up to its configured volume.
    func fadeInBGM(duration: TimeInterval = AppDuration.audioFade) {
        bgmPlayer?.setVolume(bgmVolume, fadeDuration: duration)
    }
}
