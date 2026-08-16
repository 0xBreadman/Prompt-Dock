import SwiftUI

enum ModelBadgeGroup: String, CaseIterable, Identifiable {
    case image = "图片模型"
    case video = "视频模型"
    case audio = "音频与语音"

    var id: Self { self }
}

struct ModelBadge: Identifiable, Hashable {
    let id: String
    let name: String
    let group: ModelBadgeGroup
    let accent: Color
}

enum ModelBadgeCatalog {
    static let all: [ModelBadge] = [
        // Image models
        badge("GPT", "GPT Image", .image, 0x84D8C4),
        badge("NB", "Nano Banana", .image, 0xEACB62),
        badge("MJ", "Midjourney", .image, 0x8DB6E8),
        badge("FX", "FLUX", .image, 0xC895E8),
        badge("SR", "Seedream", .image, 0xE99675),
        badge("ID", "Ideogram", .image, 0x83C8A0),
        badge("GRK", "Grok Imagine", .image, 0xD899B8),
        badge("QW", "Qwen Image", .image, 0x849EED),
        badge("SD", "Stable Diffusion", .image, 0x87C3CC),
        badge("RC", "Recraft", .image, 0x78BE98),
        badge("PHX", "Phoenix", .image, 0xE69A71),
        badge("LO", "Lucid Origin", .image, 0xB493E1),
        badge("FFI", "Firefly Image", .image, 0xEB8A69),

        // Video models
        badge("VEO", "Veo", .video, 0x70CCAA),
        badge("KL", "Kling", .video, 0xE9A35D),
        badge("SE", "Seedance", .video, 0xE87988),
        badge("RW", "Runway Gen", .video, 0x9D95E9),
        badge("HL", "Hailuo", .video, 0x65B9DD),
        badge("RAY", "Luma Ray", .video, 0xEAC664),
        badge("WAN", "Wan", .video, 0x8DC979),
        badge("FFV", "Firefly Video", .video, 0xE87963),
        badge("PK", "Pika", .video, 0xE89AAC),
        badge("PV", "PixVerse", .video, 0x879FE8),
        badge("VD", "Vidu", .video, 0x72C4D1),
        badge("HY", "Hunyuan Video", .video, 0x80B6E5),
        badge("LTX", "LTX Video", .video, 0xA58BE0),

        // Audio and voice models
        badge("SU", "Suno", .audio, 0xE99B5A),
        badge("UD", "Udio", .audio, 0x8D89E9),
        badge("EM", "Eleven Music", .audio, 0x70BFAE),
        badge("LY", "Lyria", .audio, 0xD889B6),
        badge("SA", "Stable Audio", .audio, 0x82BDC8),
        badge("MMS", "MiniMax Speech", .audio, 0xE58D84),
        badge("MMM", "MiniMax Music", .audio, 0xE8A76B),
        badge("FA", "Fish Audio", .audio, 0x68B8D0),
        badge("SON", "Cartesia Sonic", .audio, 0x85C596),
        badge("PD", "PlayDialog", .audio, 0x988EE5),
        badge("MF", "Murf Falcon", .audio, 0x76BBAA),
        badge("E11", "Eleven v3", .audio, 0x72C6B7)
    ]

    private static let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func badge(id: String?) -> ModelBadge? {
        guard let id else { return nil }
        return byID[id]
    }

    static func badges(in group: ModelBadgeGroup) -> [ModelBadge] {
        all.filter { $0.group == group }
    }

    private static func badge(
        _ id: String,
        _ name: String,
        _ group: ModelBadgeGroup,
        _ rgb: UInt32
    ) -> ModelBadge {
        ModelBadge(id: id, name: name, group: group, accent: Color(rgb: rgb))
    }
}

private extension Color {
    init(rgb: UInt32) {
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
