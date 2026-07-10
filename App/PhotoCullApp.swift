import SwiftUI

@main
struct PhotoCullApp: App {
    @StateObject private var session = CullSessionViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }
    }
}
