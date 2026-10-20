import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import HomeworkDomain

private actor RecordingTransport: HTTPTransport {
    var requests: [URLRequest] = []
    let response: HTTPResponse
    init(response: HTTPResponse) { self.response = response }
    func send(_ request: URLRequest) async throws -> HTTPResponse { requests.append(request); return response }
    func lastRequest() -> URLRequest? { requests.last }
}

final class LLMTests: XCTestCase {
    private let context = ImportContext(now: Date(timeIntervalSince1970: 1_792_454_400), timeZone: "Asia/Tokyo")

    private func item(date: Any = "2026-10-23T23:59:00+09:00", uncertain: Bool = false) -> [String: Any] {
        ["title": "Lab report", "course": "Networks", "notes": NSNull(), "dueDate": date,
         "dueTimeZone": "Asia/Tokyo", "priority": 1, "reminderAmount": 2,
         "reminderUnit": "days", "needsDateConfirmation": uncertain, "dateIssue": NSNull()]
    }

    func testStrictSchemaAndMissingDatesRequireConfirmation() throws {
        let data = try JSONSerialization.data(withJSONObject: ["assignments": [item(), item(date: NSNull(), uncertain: true)]])
        let values = try AssignmentJSONParser.parse(data, context: context)
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0].assignment.priority, .urgent)
        XCTAssertEqual(values[0].assignment.reminder, .init(amount: 2, unit: .days))
        XCTAssertTrue(values[0].ready)
        XCTAssertFalse(values[1].ready)
        var confirmed = values[1]; confirmed.dateConfirmed = true
        XCTAssertTrue(confirmed.ready)
        var extra = item(); extra["unexpected"] = true
        XCTAssertThrowsError(try AssignmentJSONParser.parse(JSONSerialization.data(withJSONObject: ["assignments": [extra]]), context: context))
        XCTAssertThrowsError(try AssignmentJSONParser.parse(Data("not JSON".utf8), context: context))
        var invalid = item(); invalid["priority"] = 9
        XCTAssertThrowsError(try AssignmentJSONParser.parse(JSONSerialization.data(withJSONObject: ["assignments": [invalid]]), context: context))
    }

    func testHTTPSAndEndpointValidation() throws {
        XCTAssertEqual(try ProviderConfiguration(baseURL: "https://example.com/v1/", model: "test").endpoint().path, "/v1/chat/completions")
        XCTAssertEqual(try ProviderConfiguration(baseURL: "https://example.com/v1/chat/completions", model: "test").endpoint().path, "/v1/chat/completions")
        for url in ["http://example.com", "https://secret@example.com", "https://example.com?key=bad", "invalid"] {
            XCTAssertThrowsError(try ProviderConfiguration(baseURL: url, model: "test").endpoint())
        }
    }

    func testContradictoryTimeZoneRequiresConfirmation() throws {
        let data = try JSONSerialization.data(withJSONObject: ["assignments": [item(date: "2026-10-23T23:59:00Z")]])
        let candidate = try XCTUnwrap(AssignmentJSONParser.parse(data, context: context).first)
        XCTAssertTrue(candidate.requiresDateConfirmation)
        XCTAssertFalse(candidate.ready)
        XCTAssertTrue(candidate.dateIssue?.contains("UTC offset") == true)
    }

    func testRequestFormatAndParsedResponse() async throws {
        let content = try JSONSerialization.data(withJSONObject: ["assignments": [item()]])
        let body = try JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": String(decoding: content, as: UTF8.self)], "finish_reason": "stop"]]])
        let transport = RecordingTransport(response: HTTPResponse(data: body, statusCode: 200))
        let provider = ChatCompletionsProvider(configuration: ProviderConfiguration(baseURL: "https://example.com/v1", model: "fixture-model"),
                                                apiKey: "synthetic-test-key", transport: transport)
        let values = try await provider.extract(LLMInput(text: "Submit this Friday."), context: context)
        XCTAssertEqual(values.count, 1)
        let savedRequest = await transport.lastRequest()
        let request = try XCTUnwrap(savedRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer synthetic-test-key")
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(object["model"] as? String, "fixture-model")
        let messages = try XCTUnwrap(object["messages"] as? [[String: Any]])
        XCTAssertTrue((messages.first?["content"] as? String)?.contains("Asia/Tokyo") == true)
    }

    func testHTTPFailuresAndUnsupportedVisionDoNotProduceCandidates() async throws {
        let transport = RecordingTransport(response: HTTPResponse(data: Data(), statusCode: 401))
        let provider = ChatCompletionsProvider(configuration: ProviderConfiguration(baseURL: "https://example.com/v1", model: "test"),
                                                apiKey: "synthetic", transport: transport)
        do { _ = try await provider.extract(LLMInput(text: "Report tomorrow"), context: context); XCTFail("Must reject HTTP 401") }
        catch { XCTAssertEqual(error as? LLMError, .http(401)) }
        do {
            _ = try await provider.extract(LLMInput(text: "", images: [LLMImage(data: Data([1]), mimeType: "image/png")]), context: context)
            XCTFail("Must reject unsupported vision")
        } catch { XCTAssertEqual(error as? LLMError, .vision) }
    }
}
