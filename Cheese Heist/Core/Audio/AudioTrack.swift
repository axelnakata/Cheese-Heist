//
//  AudioTrack.swift
//  Cheese Heist
//
//  Created by Naila Lauza on 13/08/26.
//


import Foundation

enum AudioTrack: String, CaseIterable {
    case page1 = "main"
    case page2 = "Blueprint"
    case page3 = "Angrycat"
    
    case tap1 = "Tap"
    
    case success = "Success"
    case fail = "Fail"
    
    case gear1 = "Gear1"
    case gear2 = "Gear2"
    
    case star1 = "Star1"
    case star2 = "Star2"
    case star3 = "Star3"
    
    var fileName: String {
            return self.rawValue
        }
        
        // Tentukan ekstensi spesifik berdasarkan file asli Anda
    var fileExtension: String {
            switch self {
            case .page1, .page2, .success:
                return "wav" // main menu.wav, Blueprint.wav, Success.wav
            default:
                return "mp3" // File lainnya berformat .mp3
            }
        }
}
