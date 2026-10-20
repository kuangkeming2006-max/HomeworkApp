import SwiftUI

@main
struct HomeworkApplication: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            AppNavigation(container: container)
        }
    }
}
