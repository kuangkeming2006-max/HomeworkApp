import SwiftUI
import HomeworkDomain

private struct AttachmentServiceKey: EnvironmentKey {
    static let defaultValue: (any AttachmentService)? = nil
}

extension EnvironmentValues {
    var attachmentService: (any AttachmentService)? {
        get { self[AttachmentServiceKey.self] }
        set { self[AttachmentServiceKey.self] = newValue }
    }
}
