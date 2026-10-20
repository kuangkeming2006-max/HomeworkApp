import ImageIO
import UIKit
import XCTest
@testable import HomeworkApp

@MainActor
final class ThumbnailTests: XCTestCase {
    func testLargeImageIsDownsampledBeforeReachingTheView() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1600, height: 1200), format: format).image { context in
            UIColor.systemIndigo.setFill(); context.fill(CGRect(x: 0, y: 0, width: 1600, height: 1200))
        }
        let original = try XCTUnwrap(image.jpegData(compressionQuality: 0.9))
        let service = try LocalAttachmentService(directory: root)
        let reference = try await service.importData(original, name: "synthetic.jpg", contentType: "public.jpeg")
        let cache = AttachmentThumbnailCache()
        let thumbnail = await cache.thumbnail(reference, service: service, pixels: 144)
        let data = try XCTUnwrap(thumbnail)
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        XCTAssertLessThanOrEqual(try XCTUnwrap(properties[kCGImagePropertyPixelWidth] as? Int), 144)
        XCTAssertLessThanOrEqual(try XCTUnwrap(properties[kCGImagePropertyPixelHeight] as? Int), 144)
        XCTAssertLessThan(data.count, original.count)
    }
}
