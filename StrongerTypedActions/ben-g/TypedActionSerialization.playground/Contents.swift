protocol Action {}

struct StandardAction: Action {
    let type: String
    let payload: [String : Any]
    let typedAction: Bool
}

protocol StandardActionConvertible: Action {
    init(s: StandardAction)
}

struct MyCustomAction: StandardActionConvertible {
    static let type = "MyCustomAction"
    let title: String

    init(s: StandardAction) {
        title = s.payload["title"] as! String
    }

    init(title: String) {
        self.title = title
    }
}

let typemap: [String : StandardActionConvertible.Type] = [MyCustomAction.type: MyCustomAction.self]

func decoder(standardAction: StandardAction) -> Action {
    let typedActionType = typemap[standardAction.type]!

    return typedActionType.init(s: standardAction)
}


func handleAction(action: Action) {
    if let action = action as? MyCustomAction {
        print(action.title)
    }
}

// Create a typed action directly
let regularCustomAction = MyCustomAction(title: "Test")

// Create a typed action from a standard action via decoding
let standardAction = StandardAction(type: "MyCustomAction", payload: ["title": "Good old days of Obj-C!"], typedAction: true)
let deserializedAction = decoder(standardAction)

handleAction(regularCustomAction)
handleAction(deserializedAction)


