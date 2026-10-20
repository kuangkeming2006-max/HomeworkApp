#if DEBUG
import Foundation
import HomeworkDomain

enum UITestFixtures {
    static func assignments(now: Date = Date()) -> [Assignment] {
        [Assignment(title: "Low earlier", dueDate: now.addingTimeInterval(86_400), priority: .low),
         Assignment(title: "Urgent later", dueDate: now.addingTimeInterval(345_600), priority: .urgent),
         Assignment(title: "High middle", dueDate: now.addingTimeInterval(172_800), priority: .high)]
    }
}
#endif
