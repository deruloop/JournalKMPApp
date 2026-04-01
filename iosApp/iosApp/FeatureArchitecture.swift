import Foundation
import Shared
import SwiftUI
import Observation

// MARK: - Loading State Enum
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(String)
}

// MARK: - Service
// We use a concrete type 'AsyncThrowingStream' instead of the protocol 'AsyncSequence'
// to make the type system happy in the closure definition.
struct FeatureService {
    var fetchData: () async throws -> String
    var dataStream: () -> AsyncThrowingStream<FeatureState, Error>
}

// MARK: - Live Implementation
extension FeatureService {
    static let live: FeatureService = {
        let repository = FeatureRepository()
        
        return FeatureService(
            fetchData: {
                try await repository.fetchData()
            },
            dataStream: {
                // Bridge SKIE's AsyncSequence (SkieSwiftFlow) to a standard Swift AsyncThrowingStream
                AsyncThrowingStream<FeatureState, Error> { continuation in
                    let task = Task {
                        do {
                            // Iterate over the SKIE flow
                            for await item in repository.dataStream {
                                continuation.yield(item)
                            }
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                    // Handle cancellation
                    continuation.onTermination = { @Sendable _ in
                        task.cancel()
                    }
                }
            }
        )
    }()
    
    static let mock: FeatureService = {
        return FeatureService(
            fetchData: {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                return "Mock Data"
            },
            dataStream: {
                // Mock stream yielding actual Kotlin objects
                AsyncThrowingStream<FeatureState, Error> { continuation in
                    // Use the specific Kotlin object subclasses/singletons
                    continuation.yield(FeatureState.Idle.shared)
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        continuation.yield(FeatureState.Loading.shared)
                        
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        continuation.yield(FeatureState.Success(data: "Mock Stream Data"))
                        
                        continuation.finish()
                    }
                }
            }
        )
    }()
}

// MARK: - Store
@MainActor
@Observable
class FeatureStore {
    private(set) var oneShotState: LoadingState<String> = .idle
    private(set) var streamState: LoadingState<String> = .idle
    
    private let service: FeatureService
    
    init(service: FeatureService = .live) {
        self.service = service
    }
    
    func loadData() async {
        oneShotState = .loading
        do {
            let data = try await service.fetchData()
            oneShotState = .loaded(data)
        } catch {
            oneShotState = .failed(error.localizedDescription)
        }
    }
    
    func startStream() async {
        streamState = .loading
        
        do {
            for try await state in service.dataStream() {
                // Use SKIE's onEnum(of:) to switch exhaustively on the generated Swift enum
                switch onEnum(of: state) {
                case .idle:
                    streamState = .idle
                case .loading:
                    streamState = .loading
                case .success(let data):
                    streamState = .loaded(data.data) // 'data' property from Success class
                case .error(let message):
                    streamState = .failed(message.message)
                }
            }
        } catch {
            streamState = .failed(error.localizedDescription)
        }
    }
}
