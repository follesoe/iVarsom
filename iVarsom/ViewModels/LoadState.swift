/// Keep a result and its loading status together. Region refreshes may retain the
/// previous catalog; detail loads deliberately start without a previous warning.
enum LoadState<Value> {
    case idle
    case loading(previous: Value? = nil)
    case loaded(Value)
    case failed

    var value: Value? {
        switch self {
        case .loaded(let value): value
        case .loading(let previous): previous
        case .idle, .failed: nil
        }
    }

    var phase: LoadPhase {
        switch self {
        case .idle: .idle
        case .loading: .loading
        case .loaded: .loaded
        case .failed: .failed
        }
    }
}

enum LoadPhase { case idle, loading, loaded, failed }
