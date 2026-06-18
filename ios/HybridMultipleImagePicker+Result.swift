//
//  HybridMultipleImagePicker+Result.swift
//  Pods
//
//  Created by BAO HA on 24/10/24.
//

import Foundation
import HXPhotoPicker

extension HybridMultipleImagePicker {
    /// 强制 HEIC 转码时的 JPEG 质量。必须 < 1，否则 HXPhotoPicker 不会走重新编码分支
    /// （会原样返回库内部转出的 PNG，体积巨大）。0.92 接近无损且体积可控。
    private static let heicJpegQuality: CGFloat = 0.92

    func getResult(_ asset: PhotoAsset) async throws -> PickerResult {
        // iOS Live Photo 的静态图、以及 iPhone 相机原图默认都是 HEIC。
        // HXPhotoPicker 默认沿用源格式导出 → 直接返回 .heic 文件；后端 Java ImageIO
        // 无法解码 HEIC，会在 EXIF 旋转处理时对 null 图片调用 getWidth 而抛
        // NullPointerException(500)。这里仅对 HEIC 静态图显式指定 .jpg 导出地址 +
        // 压缩质量，强制库转码为 JPEG（库内部 normalizedImage 已烘焙方向）。
        // 其余格式（JPEG/PNG/GIF）与视频保持原有行为不变。
        let heic = isHEICImage(asset)
        let urlResult: AssetURLResult
        if heic {
            let jpegURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            urlResult = try await asset.urlResult(
                .init(imageCompressionQuality: Self.heicJpegQuality),
                toFile: .init(imageURL: jpegURL)
            )
        } else {
            urlResult = try await asset.urlResult()
        }
        let url = urlResult.url

        let creationDate = Int(asset.phAsset?.creationDate?.timeIntervalSince1970 ?? 0)

        let mime = url.getMimeType()

        let phAsset = asset.phAsset

        let type: ResultType = .init(fromString: asset.mediaType == .video ? "video" : "image")!
        let thumbnail = asset.phAsset?.getVideoAssetThumbnail(from: url.absoluteString, in: 1)

        return PickerResult(localIdentifier: phAsset!.localIdentifier,
                            width: asset.imageSize.width,
                            height: asset.imageSize.height,
                            mime: mime,
                            size: Double(asset.fileSize),
                            bucketId: nil,
                            realPath: nil,
                            parentFolderName: nil,
                            creationDate: creationDate > 0 ? Double(creationDate) : nil,
                            crop: false,
                            path: "file://\(url.absoluteString)",
                            type: type,
                            duration: asset.videoDuration,
                            thumbnail: thumbnail,
                            // 转码后字节已是 JPEG，文件名后缀同步改成 .jpg，否则后端会沿用
                            // 原始 .HEIC 后缀存储/分发，导致客户端渲染异常。
                            fileName: heic ? jpegFileName(phAsset?.fileName) : phAsset?.fileName)
    }

    /// 仅「静态图片且原始资源为 HEIC/HEIF」时返回 true（视频、GIF 不处理）。
    private func isHEICImage(_ asset: PhotoAsset) -> Bool {
        guard asset.mediaType != .video, !asset.isGifAsset else { return false }
        let name = (asset.phAsset?.fileName ?? "").lowercased()
        return name.hasSuffix(".heic") || name.hasSuffix(".heif")
    }

    /// 把原文件名后缀替换为 jpg，保留原始主名；无主名时返回 nil 交由上层兜底命名。
    private func jpegFileName(_ original: String?) -> String? {
        guard let original, !original.isEmpty else { return nil }
        let base = (original as NSString).deletingPathExtension
        return base.isEmpty ? nil : "\(base).jpg"
    }
}
