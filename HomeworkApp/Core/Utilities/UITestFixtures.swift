#if DEBUG
import Foundation
import UIKit
import HomeworkDomain

enum UITestFixtures {
    static func performanceAssignments(now: Date = Date()) -> [Assignment] {
        (0..<600).map { index in
            Assignment(title: "Synthetic coursework \(index)", course: "Course \(index % 12)", notes: "Synthetic instructions",
                       dueDate: now.addingTimeInterval(Double(index + 1) * 3600),
                       priority: Priority(rawValue: index % 4 + 1) ?? .medium, now: now)
        }
    }
    static func assignments(now: Date = Date()) -> [Assignment] {
        [Assignment(title: "Low earlier", dueDate: now.addingTimeInterval(86_400), priority: .low),
         Assignment(title: "Urgent later", dueDate: now.addingTimeInterval(345_600), priority: .urgent),
         Assignment(title: "High middle", dueDate: now.addingTimeInterval(172_800), priority: .high)]
    }

    @MainActor
    static func designAssignments(service: any AttachmentService, now: Date = Date()) async throws -> [Assignment] {
        var task = Assignment(title: "Networking laboratory report with a deliberately long title that should stay within two lines in the list",
                              course: "Computer networks and distributed systems — extended course title", notes: "Synthetic coursework instructions.\nInclude the packet capture analysis and final discussion.",
                              dueDate: now.addingTimeInterval(3600), priority: .urgent, reminder: .init(amount: 30, unit: .minutes))
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 800)).image { context in
            UIColor.systemIndigo.setFill(); context.fill(CGRect(x: 0, y: 0, width: 1200, height: 800))
            ("Synthetic lab notes" as NSString).draw(at: CGPoint(x: 90, y: 320), withAttributes: [.font: UIFont.systemFont(ofSize: 72), .foregroundColor: UIColor.white])
        }
        guard let data = image.jpegData(compressionQuality: 0.8) else { throw AssignmentError.invalid("Synthetic image generation failed.") }
        let pdf = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)).pdfData { context in
            context.beginPage()
            ("Synthetic assignment handout" as NSString).draw(at: CGPoint(x: 48, y: 72), withAttributes: [.font: UIFont.systemFont(ofSize: 24)])
        }
        task.attachments = [try await service.importData(data, name: "Lab notes.jpg", contentType: "public.jpeg"),
                            try await service.importData(pdf, name: "Assignment handout.pdf", contentType: "com.adobe.pdf")]
        var completed = Assignment(title: "Finished problem set", dueDate: now, now: now)
        completed.transition(to: .completed, at: now)
        var abandoned = Assignment(title: "Optional reading", dueDate: now, now: now)
        abandoned.transition(to: .abandoned, at: now)
        let overdue = Assignment(title: "Earlier lab report", dueDate: now.addingTimeInterval(-7200), now: now)
        return [task, completed, abandoned, overdue]
    }
}
#endif
