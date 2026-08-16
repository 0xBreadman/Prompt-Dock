import Foundation

struct PromptLibrary: Codable, Equatable {
    static let currentSchemaVersion = 6

    var schemaVersion: Int
    var categories: [PromptCategory]
    var prompts: [PromptItem]
    var presets: [DockPreset]

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        categories: [PromptCategory] = [],
        prompts: [PromptItem] = [],
        presets: [DockPreset] = []
    ) {
        self.schemaVersion = schemaVersion
        self.categories = categories
        self.prompts = prompts
        self.presets = presets
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case categories
        case prompts
        case presets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        guard decodedVersion <= Self.currentSchemaVersion else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unsupported Prompt library schema version \(decodedVersion)."
            )
        }
        categories = try container.decodeIfPresent([PromptCategory].self, forKey: .categories) ?? []
        prompts = try container.decodeIfPresent([PromptItem].self, forKey: .prompts) ?? []
        presets = try container.decodeIfPresent([DockPreset].self, forKey: .presets) ?? []
        schemaVersion = Self.currentSchemaVersion

        if decodedVersion < 5 {
            migratePresetBadgesToPrompts()
        }

        if presets.isEmpty {
            presets = [
                DockPreset(
                    name: "全部提示词",
                    symbolName: "square.grid.2x2",
                    promptIDs: prompts.map(\.id)
                )
            ]
        }
    }

    private mutating func migratePresetBadgesToPrompts() {
        for promptIndex in prompts.indices where prompts[promptIndex].primaryModelBadgeID == nil {
            let promptID = prompts[promptIndex].id
            let inheritedBadges: Set<String> = Set(
                presets.compactMap { preset -> String? in
                    guard preset.promptIDs.contains(promptID) else { return nil }
                    return preset.modelBadgeID
                }
            )
            if inheritedBadges.count == 1 {
                prompts[promptIndex].primaryModelBadgeID = inheritedBadges.first
            }
        }

        for index in presets.indices {
            presets[index].modelBadgeID = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentSchemaVersion, forKey: .schemaVersion)
        try container.encode(categories, forKey: .categories)
        try container.encode(prompts, forKey: .prompts)
        try container.encode(presets, forKey: .presets)
    }
}

extension PromptLibrary {
    static let starter: PromptLibrary = {
        let image = PromptCategory(name: "图片生成", symbolName: "photo.on.rectangle.angled", sortOrder: 0)
        let video = PromptCategory(name: "视频生成", symbolName: "video.fill", sortOrder: 1)
        let ecommerce = PromptCategory(name: "Shopify", symbolName: "bag.fill", sortOrder: 2)

        let prompts = [
                PromptItem(
                    title: "图生图基础 Prompt",
                    content: "请在保留主体身份、产品结构和关键细节一致性的前提下，按照我提供的参考图生成新的场景。保持真实材质、自然光线和可信的比例，不添加参考图中不存在的品牌元素。",
                    categoryID: image.id,
                    tags: ["img2img", "reference"],
                    primaryModelBadgeID: "GPT",
                    sortOrder: 0
                ),
                PromptItem(
                    title: "产品一致性规则",
                    content: "产品一致性优先级：轮廓、结构、颜色、材质、装饰细节。任何场景变化都不得改变产品本身；如参考信息不足，保持克制，不自行补充不可见结构。",
                    categoryID: image.id,
                    tags: ["product", "consistency"],
                    primaryModelBadgeID: "NB",
                    sortOrder: 1
                ),
                PromptItem(
                    title: "UGC 摄影规则",
                    content: "生成自然、可信的生活方式 UGC 画面。使用轻微不完美的手持构图、柔和环境光和真实居家背景，避免影棚感、过度磨皮、夸张景深和不自然的商业姿势。",
                    categoryID: image.id,
                    tags: ["ugc", "photo"],
                    primaryModelBadgeID: "MJ",
                    sortOrder: 2
                ),
                PromptItem(
                    title: "图生视频 Prompt",
                    content: "基于输入图片生成短视频。锁定主体身份、服装、产品外观和背景结构；动作应自然连续，镜头运动缓慢稳定，不产生形变、闪烁、额外肢体或物体漂移。",
                    categoryID: video.id,
                    tags: ["video", "image-to-video"],
                    primaryModelBadgeID: "VEO",
                    compatibleModelBadgeIDs: ["KL", "SE"],
                    sortOrder: 0
                ),
                PromptItem(
                    title: "镜头规则",
                    content: "采用克制的电影感镜头语言：缓慢推进、轻微横移或稳定手持三选一。单个镜头只使用一种主要运动，主体始终清晰，不使用突然变焦和无动机环绕。",
                    categoryID: video.id,
                    tags: ["camera", "video"],
                    primaryModelBadgeID: "KL",
                    sortOrder: 1
                ),
                PromptItem(
                    title: "产品描述模板",
                    content: "请根据产品事实撰写简洁的 Shopify 产品描述：先说明它解决的使用问题，再写核心特点、真实使用场景、材质与护理信息。避免无法证实的效果、绝对化承诺和空泛形容词。",
                    categoryID: ecommerce.id,
                    tags: ["shopify", "product-copy"],
                    sortOrder: 0
                ),
                PromptItem(
                    title: "SEO 模板",
                    content: "请输出页面标题、Meta Description、URL handle、H1、简短导语和 3 个 FAQ。自然包含主要关键词，优先可读性与搜索意图，不堆砌关键词，不编造产品属性。",
                    categoryID: ecommerce.id,
                    tags: ["shopify", "seo"],
                    sortOrder: 1
                )
            ]

        let all = DockPreset(
            name: "全部提示词",
            symbolName: "square.grid.2x2",
            sortOrder: 0,
            promptIDs: prompts.map(\.id),
            quickPromptIDs: Array(prompts.prefix(6).map(\.id))
        )
        let content = DockPreset(
            name: "AI 内容制作",
            symbolName: "sparkles",
            sortOrder: 1,
            promptIDs: prompts.filter { $0.categoryID == image.id || $0.categoryID == video.id }.map(\.id),
            quickPromptIDs: Array(prompts.filter { $0.categoryID == image.id || $0.categoryID == video.id }.prefix(6).map(\.id))
        )
        let shopify = DockPreset(
            name: "Shopify 运营",
            symbolName: "bag.fill",
            sortOrder: 2,
            promptIDs: prompts.filter { $0.categoryID == ecommerce.id }.map(\.id),
            quickPromptIDs: prompts.filter { $0.categoryID == ecommerce.id }.map(\.id)
        )

        return PromptLibrary(
            categories: [image, video, ecommerce],
            prompts: prompts,
            presets: [all, content, shopify]
        )
    }()
}
