import Dispatch


public protocol StoreType {
    typealias ActionType
    typealias StateType
    
    init(reducer: (StateType, ActionType) -> StateType, state: StateType)
    
    func dispatch(action: ActionType, callback: (StateType -> Void)?)
}


public class Store<A, S> {
    public typealias ActionType = A
    public typealias StateType = S
        
    private let reducer: (S, A) -> S
    private(set) public var state: S
    
    public required init(reducer: (S, A) -> S, state: S) {
        self.reducer = reducer
        self.state = state
    }
    
    public func dispatch(action: A, callback: (S -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.state = self.reducer(self.state, action)
            callback?(self.state)
        }
    }
}
