import Foundation


func _identityAsString(value: AnyObject?) -> String {
    if value == nil {
        return "nil"
    }
    return NSString(format: "<%p>", unsafeBitCast(value!, Int.self))
}

func _arrayAsString<T>(items: [T], joiner: String = ", ") -> String {
    return items.reduce("") { accum, item in
        let prefix = (accum.isEmpty ? "" : joiner)
        return accum + prefix + "\(item)"
    }
}

@objc protocol NMBStringer {
    func NMB_stringify() -> String
}

func stringify<S: SequenceType>(value: S) -> String {
    var generator = value.generate()
    var strings = [String]()
    var value: S.Generator.Element?
    do {
        value = generator.next()
        if value != nil {
            strings.append(stringify(value))
        }
    } while value != nil
    let str = ", ".join(strings)
    return "[\(str)]"
}

extension NSArray : NMBStringer {
    func NMB_stringify() -> String {
        let str = self.componentsJoinedByString(", ")
        return "[\(str)]"
    }
}

func stringify<T>(value: T) -> String {
    if value is Double {
        return NSString(format: "%.4f", (value as Double))
    }
    return toString(value)
}

func stringify<T>(value: T?) -> String {
    if let unboxed = value {
       return stringify(unboxed)
    }
    return "nil"
}
