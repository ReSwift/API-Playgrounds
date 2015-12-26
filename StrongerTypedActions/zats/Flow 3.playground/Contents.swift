import Foundation
import XCPlayground

let playgroundPage = XCPlaygroundPage.currentPage
playgroundPage.needsIndefiniteExecution = true

// MARK: Utility

func combineReducers<A, S>(reducers: ((S, A) -> S) ...) -> ((S, A) -> S) {
    return {(var state, action) in
        for reducer in reducers {
            state = reducer(state, action)
        }
        return state
    }
}

// MARK: JSONSerializable

extension AppState: JSONSerializable {
    init?(json: [String : AnyObject]) {
        guard let URLs = json["URLs"] as? [String] else {
            return nil
        }
        self.URLs = URLs
    }
    
    var jsonValue: [String: AnyObject] {
        return ["URLs": URLs]
    }
}

// MARK: Usage

struct AppState {
    var URLs: [String] = []
}

enum Action {
    case Add(URL: String)
    case Remove(index: Int)
}

extension Action: JSONSerializable {
    init?(json: [String : AnyObject]) {
        switch json["type"] as? String {
        case "add"?:
            guard let URL = json["URL"] as? String else {
                return nil
            }
            self = .Add(URL: URL)
        case "remove"?:
            guard let index = json["index"] as? Int else {
                return nil
            }
            self = .Remove(index: index)
        default:
            return nil
        }
    }
    
    var jsonValue: [String: AnyObject] {
        switch self {
        case let .Add(URL):
            return ["type": "add", "URL": URL]
        case let .Remove(index):
            return ["type": "remove", "index": index]
        }
    }
}

// Reducers

// Recorder

let recordURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
let recorder: RecordingReducer<AppState, Action> = RecordingReducer(recordURL: recordURL)

typealias AppReducer = (AppState, Action) -> AppState

let addReducer: AppReducer = { (var state, action) in
    if case let .Add(URL) = action {
        state.URLs.append(URL)
    }
    return state
}

let removeReducer: AppReducer = { (var state, action) in
    if case let .Remove(index) = action {
        state.URLs.removeAtIndex(index)
    }
    return state
}

//assertionFailure("First time you run, set `let isRecording = true`, second time set it to `false` to replay actions")
let isRecording = false

var store = Store<Action, AppState>(
    reducer: combineReducers(recorder.recordingReducer, addReducer, removeReducer),
    state: AppState(
        URLs: ["URL1", "URL2"]
    )
)

print("You can find recording at \(recordURL.relativePath!)")

if isRecording {
    // Make sure we record into empty directory
    let fileManager = NSFileManager.defaultManager()
    if let enumerator = fileManager.enumeratorAtURL(recordURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
        for URL in enumerator {
            try? fileManager.removeItemAtURL(URL as! NSURL)
        }
    }
    
    store.dispatch(.Add(URL: "URL3"))
    store.dispatch(.Remove(index: 2))
    store.dispatch(.Add(URL: "URL4"), callback: { _ in
        // all actions has been recorded
        print("Done recording")
        assert(store.state.URLs.count == 3)
    })
} else {
    store.restoreActions(recordURL) { didFinish in
        // all actions has been restored
        print(store.state)
        assert(store.state.URLs.count == 3)
    }
}
