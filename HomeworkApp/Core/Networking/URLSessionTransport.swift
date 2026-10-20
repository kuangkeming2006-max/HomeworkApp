import Foundation
import HomeworkDomain

private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

actor URLSessionTransport: HTTPTransport {
    private let session: URLSession
    private let redirectPolicy = NoRedirectDelegate()

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 60
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        session = URLSession(configuration: configuration, delegate: redirectPolicy, delegateQueue: nil)
    }

    func send(_ request: URLRequest) async throws -> HTTPResponse {
        let (bytes, response) = try await session.bytes(for: request)
        guard let response = response as? HTTPURLResponse else { throw LLMError.response }
        guard response.expectedContentLength <= 2_097_152 else { throw LLMError.response }
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
            if data.count > 2_097_152 { throw LLMError.response }
        }
        return HTTPResponse(data: data, statusCode: response.statusCode)
    }
}
