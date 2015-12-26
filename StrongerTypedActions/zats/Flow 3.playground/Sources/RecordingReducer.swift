import Foundation


public protocol Serializable {
    init?(data: NSData)
    var data: NSData? { get }
}

public protocol JSONSerializable: Serializable {
    init?(json: [String: AnyObject])
    var jsonValue: [String: AnyObject] { get }
}

public extension JSONSerializable {
    init?(data: NSData) {
        guard let rawJson = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
            json = rawJson as? [String: AnyObject] else {
                return nil
        }
        self.init(json: json)
    }
    
    var data: NSData? {
        return try? NSJSONSerialization.dataWithJSONObject(jsonValue, options: [])
    }
}

public final class RecordingReducer<S, A: Serializable> {
    public let recordURL: NSURL
    
    private let fileManager = NSFileManager.defaultManager()
    private let recordingQueue: dispatch_queue_t = {
        let attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, -1)
        return dispatch_queue_create("com.swift-flow.recording-queue", attr)
    }()
    
    public init(recordURL: NSURL) {
        self.recordURL = recordURL
    }
    
    public func recordingReducer(state: S, action: A) -> S {
        dispatch_async(recordingQueue) {
            guard let data = action.data else {
                assertionFailure("Failed to serialize data")
                return
            }
            let timestamp = NSDate().timeIntervalSince1970
            let URL = self.recordURL.URLByAppendingPathComponent("\(timestamp).json")
            let result = data.writeToURL(URL, atomically: true)
            assert(result, "Failed to record the action to \(URL)")
        }
        return state
    }
}

public extension Store where A: Serializable {
    public func restoreActions(recordURL: NSURL, completion: (Bool -> Void)?) {
        let fileManger = NSFileManager.defaultManager()
        guard let enumerator = fileManger.enumeratorAtURL(recordURL, includingPropertiesForKeys: nil, options: [.SkipsSubdirectoryDescendants, .SkipsPackageDescendants], errorHandler: nil) else {
            completion?(false)
            return
        }
        let URLs = (enumerator.allObjects as! [NSURL]).filter{ $0.pathExtension?.hasSuffix("json") == true }
        restoreActionsRecursively(URLs, completion: completion)
    }
    
    private func restoreActionsRecursively(URLs: [NSURL], completion: (Bool -> Void)?) {
        guard let URL = URLs.first else {
            // end of the recursion
            completion?(true)
            return
        }
        guard let data = NSData(contentsOfURL: URL), action = A(data: data) else {
            assertionFailure("Failed to read action at URL \(URL)")
            self.restoreActionsRecursively(Array(URLs.dropFirst()), completion: completion)
            return
        }
        dispatch(action) { _ in
            self.restoreActionsRecursively(Array(URLs.dropFirst()), completion: completion)
        }
    }
}