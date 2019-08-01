import Nimble

/// A Nimble matcher that succeeds when at least one of the substrings
public func containOne(of substrings: String...) -> Predicate<String> {
    return containOne(of: substrings)
}

/// A Nimble matcher that succeeds when at least one of the substrings
public func containOne(of substrings: [String]) -> Predicate<String> {
    let containArrayAsString = substrings.map { "<\($0)>" }.joined(separator: " or ")
    return Predicate.simple("contain \(containArrayAsString)") { actualExpression in
        if let actual = try actualExpression.evaluate() {
            let foundSubsring = substrings.first(where: { actual.contains($0) })
            return PredicateStatus(bool: foundSubsring != nil)
        }
        return .fail
    }
}
