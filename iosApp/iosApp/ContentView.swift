import SwiftUI
import Shared

struct ContentView: View {
    var body: some View {
        TabView {
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
            
            DemoView()
                .tabItem {
                    Label("Demo", systemImage: "gear")
                }
        }
    }
}

struct DemoView: View {
    @State private var store = FeatureStore()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("SKIE + Swift Architecture")
                .font(.title)
                .bold()
            
            // Section 1: One-Shot Async Call
            VStack {
                Text("One-Shot Data")
                // ... (rest of the view logic)
                switch store.oneShotState {
                case .idle:
                    Text("Ready to fetch")
                    Button("Fetch Data") {
                        Task { await store.loadData() }
                    }
                    .buttonStyle(.borderedProminent)
                    
                case .loading:
                    ProgressView("Fetching...")
                    
                case .loaded(let data):
                    Text(data)
                        .foregroundColor(.green)
                    Button("Reset") {
                        Task { await store.loadData() }
                    }
                    
                case .failed(let error):
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Section 2: Real-time Stream (Flow)
            VStack {
                Text("Real-time Stream")
                
                switch store.streamState {
                case .idle:
                    Button("Start Stream") {
                        Task { await store.startStream() }
                    }
                    .buttonStyle(.bordered)
                    
                case .loading:
                    ProgressView("Waiting for stream...")
                    
                case .loaded(let data):
                    Text(data)
                        .font(.largeTitle)
                        .transition(.scale)
                    
                case .failed(let error):
                    Text("Stream Error: \(error)")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
