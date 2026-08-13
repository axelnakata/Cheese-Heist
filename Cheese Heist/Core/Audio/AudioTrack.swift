import Foundation

enum AudioTrack: String, CaseIterable {
    case page1 = "bgm_page1"
    case page2 = "bgm_page2"
    case page3 = "bgm_page3"
    case page4 = "bgm_page4"
    case page5 = "bgm_page5"
    case page6 = "bgm_page6"
    case page7 = "bgm_page7"
    case page8 = "bgm_page8"
    case page9 = "bgm_page9"
    
    var fileName: String {
        return self.rawValue
    }
    
    var fileExtension: String {
        return "mp3" // Sesuaikan jika ada file .m4a atau .wav
    }
}