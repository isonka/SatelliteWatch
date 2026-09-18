import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                Text("Launches")
                    .navigationTitle("Launches")
            }
            .tabItem {
                Label("Launches", systemImage: "airplane.departure")
            }

            NavigationStack {
                Text("Rockets")
                    .navigationTitle("Rockets")
            }
            .tabItem {
                Label("Rockets", systemImage: "airplane")
            }
        }
    }
}

#Preview {
    ContentView()
}
