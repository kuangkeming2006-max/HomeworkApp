import Foundation
import ImageIO
import UniformTypeIdentifiers
import HomeworkDomain

/// Bounded, resized JPEG cache. Image decoding and encoding run on this actor, off the main actor.
actor AttachmentThumbnailCache {
    static let shared = AttachmentThumbnailCache()
    private var cache: [String: Data] = [:]
    private var order: [String] = []
    private var bytes = 0
    private let budget = 16 * 1024 * 1024

    func thumbnail(_ reference: AttachmentReference, service: any AttachmentService, pixels: Int) async -> Data? {
        guard UTType(reference.contentType)?.conforms(to: .image) == true else { return nil }
        let key = "\(reference.sha256).\(pixels)"
        if let data = cache[key] { return data }
        guard let url = try? await service.url(for: reference),
              let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: pixels,
                kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        let data = output as Data
        // Concurrent requests may have filled the same key during the URL await.
        if cache[key] != nil { return cache[key] }
        while bytes + data.count > budget, !order.isEmpty {
            let oldest = order.removeFirst(); bytes -= cache.removeValue(forKey: oldest)?.count ?? 0
        }
        cache[key] = data; order.append(key); bytes += data.count
        return data
    }
}
