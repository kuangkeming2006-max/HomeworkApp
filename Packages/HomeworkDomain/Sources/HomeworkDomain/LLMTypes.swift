import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct ProviderConfiguration: Codable, Equatable, Sendable {
    public var baseURL: String
    public var model: String
    public var supportsImages: Bool
    public var useJSONMode: Bool

    public init(baseURL: String = "", model: String = "", supportsImages: Bool = false, useJSONMode: Bool = true) {
        self.baseURL = baseURL; self.model = model
        self.supportsImages = supportsImages; self.useJSONMode = useJSONMode
    }

    public func endpoint() throws -> URL {
        guard var parts = URLComponents(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              parts.scheme?.lowercased() == "https", let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil, parts.query == nil, parts.fragment == nil,
              !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, model.count <= 200 else {
            throw LLMError.configuration
        }
        let path = parts.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        parts.path = path.isEmpty ? "" : "/" + path
        guard let base = parts.url else { throw LLMError.configuration }
        if base.path.hasSuffix("/chat/completions") { return base }
        return base.appendingPathComponent("chat").appendingPathComponent("completions")
    }
}

public struct LLMImage: Sendable {
    public let data: Data
    public let mimeType: String
    public init(data: Data, mimeType: String) { self.data = data; self.mimeType = mimeType }
}

public struct LLMInput: Sendable {
    public let text: String
    public let images: [LLMImage]
    public init(text: String, images: [LLMImage] = []) { self.text = text; self.images = images }

    public func validate() throws {
        guard text.count <= 16_000, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !images.isEmpty,
              images.count <= 4, images.reduce(0, { $0 + $1.data.count }) <= 8 * 1024 * 1024,
              images.allSatisfy({ !$0.data.isEmpty && $0.data.count <= 4 * 1024 * 1024 &&
                                  ["image/jpeg", "image/png", "image/webp"].contains($0.mimeType) }) else {
            throw LLMError.input
        }
    }
}

public struct ImportContext: Sendable {
    public let now: Date
    public let timeZone: String
    public let defaultReminder: ReminderConfiguration
    public init(now: Date = Date(), timeZone: String = TimeZone.current.identifier,
                defaultReminder: ReminderConfiguration = .none) {
        self.now = now; self.timeZone = timeZone; self.defaultReminder = defaultReminder
    }
}

public struct ImportCandidate: Identifiable, Equatable, Sendable {
    public var assignment: Assignment
    public var requiresDateConfirmation: Bool
    public var dateIssue: String?
    public var dateConfirmed = false
    public var selected = true
    public var id: UUID { assignment.id }
    public var ready: Bool { (!requiresDateConfirmation || dateConfirmed) && (try? assignment.validate()) != nil }

    public init(assignment: Assignment, requiresDateConfirmation: Bool, dateIssue: String? = nil) {
        self.assignment = assignment; self.requiresDateConfirmation = requiresDateConfirmation; self.dateIssue = dateIssue
    }
}

public protocol LLMProvider: Sendable {
    func extract(_ input: LLMInput, context: ImportContext) async throws -> [ImportCandidate]
    func testConnection() async throws -> String
}

public struct HTTPResponse: Sendable {
    public let data: Data
    public let statusCode: Int
    public init(data: Data, statusCode: Int) { self.data = data; self.statusCode = statusCode }
}

public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> HTTPResponse
}

@MainActor
public protocol SecretStore {
    func readKey() throws -> String?
    func saveKey(_ key: String) throws
    func deleteKey() throws
}

public enum LLMError: LocalizedError, Equatable, Sendable {
    case configuration, missingKey, input, vision, response, schema, truncated, http(Int), network
    public var errorDescription: String? {
        switch self {
        case .configuration: "Enter an HTTPS base URL without credentials, query or fragment, and a model name. Include your provider's API path, such as /v1."
        case .missingKey: "Save your API key in Settings before using AI."
        case .input: "Enter text or choose up to four images. Text is limited to 16,000 characters and images to 4 MB each, 8 MB in total."
        case .vision: "This provider is not configured for images. Choose a vision model and enable image input in Settings."
        case .response: "The provider returned an unreadable response. Try again or use manual entry."
        case .schema: "The AI response did not match the assignment format. Nothing was saved. Try a clearer input or manual entry."
        case .truncated: "The AI response was cut off. Try importing fewer assignments at once."
        case .http(401), .http(403): "The provider rejected your credentials. Check the API key and model access in Settings."
        case .http(429): "The provider's rate or usage limit was reached. Try again later or check your provider account."
        case .http(400), .http(422): "The provider rejected the request. Check the model, image support and JSON mode in Settings."
        case .http(let code): "The provider returned HTTP \(code). Try again later or check the base URL."
        case .network: "The AI request could not finish. Check your connection, HTTPS certificate and provider settings."
        }
    }
}
