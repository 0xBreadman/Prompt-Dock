import SwiftUI
import UniformTypeIdentifiers

struct LibrarySettingsView: View {
    @EnvironmentObject private var store: PromptStore
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var pendingImportURL: URL?
    @State private var operationError: String?
    @State private var exportDocument = PromptLibraryDocument(library: PromptLibrary())

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("数据与备份")
                        .font(.title2.bold())
                    Text("Prompt 正文保存在本机；导出的 JSON 可以完整恢复分类、预设和转盘槽位。")
                        .foregroundStyle(.secondary)
                }

                dataCard(
                    symbol: "externaldrive.fill",
                    title: "本地资料库",
                    subtitle: "当前共有 \(store.library.categories.count) 个分类、\(store.library.prompts.count) 条 Prompt、\(store.library.presets.count) 套工作预设。"
                ) {
                    Label("运行在 App 沙盒的 Application Support 目录", systemImage: "lock.shield")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("每天首次修改前，App 会在本地 Backups 文件夹保留一份当日快照。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                dataCard(
                    symbol: "arrow.up.doc.fill",
                    title: "导出完整备份",
                    subtitle: "适合迁移电脑、存入移动硬盘，或在大规模编辑前留档。"
                ) {
                    Button {
                        exportDocument = PromptLibraryDocument(library: store.library)
                        isExporting = true
                    } label: {
                        Label("导出 JSON…", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                }

                dataCard(
                    symbol: "arrow.down.doc.fill",
                    title: "导入并恢复",
                    subtitle: "选择 Prompt Dock 导出的 JSON；确认后会替换当前资料库。"
                ) {
                    Button {
                        isImporting = true
                    } label: {
                        Label("选择备份文件…", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                }

                if let url = pendingImportURL {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("确认替换当前资料库", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        Text("将使用“\(url.lastPathComponent)”替换当前分类、Prompt 和工作预设。系统会先保留今天的本地自动备份。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button("取消") {
                                pendingImportURL = nil
                            }
                            Spacer()
                            Button("导入并替换", role: .destructive) {
                                do {
                                    try store.importLibrary(from: url)
                                    pendingImportURL = nil
                                    operationError = nil
                                } catch {
                                    operationError = error.localizedDescription
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }
                    .padding(16)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.orange.opacity(0.24), lineWidth: 0.7)
                    }
                }

                if let operationError {
                    Label(operationError, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }

                if let notice = store.noticeMessage {
                    Label(notice, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                pendingImportURL = urls.first
                operationError = nil
            case .failure(let error):
                operationError = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: defaultBackupName
        ) { result in
            switch result {
            case .success:
                store.showNotice("完整备份已导出。")
            case .failure(let error):
                // The exporter owns the destination URL; surface errors locally.
                operationError = error.localizedDescription
            }
        }
    }

    private var defaultBackupName: String {
        "AI-Prompt-Dock-Backup-\(Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash)))"
    }

    private func dataCard<Content: View>(
        symbol: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Divider().opacity(0.55)
            content()
        }
        .padding(18)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.6)
        }
    }
}

struct PromptLibraryDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var library: PromptLibrary

    init(library: PromptLibrary) {
        self.library = library
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        library = try JSONPromptRepository.decoder.decode(PromptLibrary.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try JSONPromptRepository.encoder.encode(library))
    }
}
