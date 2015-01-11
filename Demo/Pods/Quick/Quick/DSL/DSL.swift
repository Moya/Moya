/**
    Defines a closure to be run prior to any examples in the test suite.
    You may define an unlimited number of these closures, but there is no
    guarantee as to the order in which they're run.

    If the test suite crashes before the first example is run, this closure
    will not be executed.

    :param: closure The closure to be run prior to any examples in the test suite.
*/
public func beforeSuite(closure: BeforeSuiteClosure) {
    World.sharedWorld().beforeSuite(closure)
}

/**
    Defines a closure to be run after all of the examples in the test suite.
    You may define an unlimited number of these closures, but there is no
    guarantee as to the order in which they're run.

    If the test suite crashes before all examples are run, this closure
    will not be executed.

    :param: closure The closure to be run after all of the examples in the test suite.
*/
public func afterSuite(closure: AfterSuiteClosure) {
    World.sharedWorld().afterSuite(closure)
}

/**
    Defines a group of shared examples. These examples can be re-used in several locations
    by using the `itBehavesLike` function.

    :param: name The name of the shared example group. This must be unique across all shared example
                 groups defined in a test suite.
    :param: closure A closure containing the examples. This behaves just like an example group defined
                    using `describe` or `context`--the closure may contain any number of `beforeEach`
                    and `afterEach` closures, as well as any number of examples (defined using `it`).
*/
public func sharedExamples(name: String, closure: () -> ()) {
    World.sharedWorld().sharedExamples(name, closure: { (NSDictionary) in closure() })
}

/**
    Defines a group of shared examples. These examples can be re-used in several locations
    by using the `itBehavesLike` function.

    :param: name The name of the shared example group. This must be unique across all shared example
                 groups defined in a test suite.
    :param: closure A closure containing the examples. This behaves just like an example group defined
                    using `describe` or `context`--the closure may contain any number of `beforeEach`
                    and `afterEach` closures, as well as any number of examples (defined using `it`).

                    The closure takes a SharedExampleContext as an argument. This context is a function
                    that can be executed to retrieve parameters passed in via an `itBehavesLike` function.
*/
public func sharedExamples(name: String, closure: SharedExampleClosure) {
    World.sharedWorld().sharedExamples(name, closure: closure)
}

/**
    Defines an example group. Example groups are logical groupings of examples.
    Example groups can share setup and teardown code.

    :param: description An arbitrary string describing the example group.
    :param: closure A closure that can contain other examples.
*/
public func describe(description: String, closure: () -> ()) {
    World.sharedWorld().describe(description, closure: closure)
}

/**
    Defines an example group. Equivalent to `describe`.
*/
public func context(description: String, closure: () -> ()) {
    describe(description, closure)
}

/**
    Defines a closure to be run prior to each example in the current example
    group. This closure is not run for pending or otherwise disabled examples.
    An example group may contain an unlimited number of beforeEach. They'll be
    run in the order they're defined, but you shouldn't rely on that behavior.

    :param: closure The closure to be run prior to each example.
*/
public func beforeEach(closure: BeforeExampleClosure) {
    World.sharedWorld().beforeEach(closure)
}

/**
    Identical to Quick.DSL.beforeEach, except the closure is provided with
    metadata on the example that the closure is being run prior to.
*/
public func beforeEach(#closure: BeforeExampleWithMetadataClosure) {
    World.sharedWorld().beforeEach(closure: closure)
}

/**
    Defines a closure to be run after each example in the current example
    group. This closure is not run for pending or otherwise disabled examples.
    An example group may contain an unlimited number of afterEach. They'll be
    run in the order they're defined, but you shouldn't rely on that behavior.

    :param: closure The closure to be run after each example.
*/
public func afterEach(closure: AfterExampleClosure) {
    World.sharedWorld().afterEach(closure)
}

/**
    Identical to Quick.DSL.afterEach, except the closure is provided with
    metadata on the example that the closure is being run after.
*/
public func afterEach(#closure: AfterExampleWithMetadataClosure) {
    World.sharedWorld().afterEach(closure: closure)
}

/**
    Defines an example. Examples use assertions to demonstrate how code should
    behave. These are like "tests" in XCTest.

    :param: description An arbitrary string describing what the example is meant to specify.
    :param: closure A closure that can contain assertions.
    :param: file The absolute path to the file containing the example. A sensible default is provided.
    :param: line The line containing the example. A sensible default is provided.
*/
public func it(description: String, closure: () -> (), file: String = __FILE__, line: Int = __LINE__) {
    World.sharedWorld().it(description, file: file, line: line, closure: closure)
}

/**
    Inserts the examples defined using a `sharedExamples` function into the current example group.
    The shared examples are executed at this location, as if they were written out manually.

    :param: name The name of the shared examples group to be executed. This must be identical to the
                 name of a shared examples group defined using `sharedExamples`. If there are no shared
                 examples that match the name given, an exception is thrown and the test suite will crash.
    :param: file The absolute path to the file containing the current example group. A sensible default is provided.
    :param: line The line containing the current example group. A sensible default is provided.
*/
public func itBehavesLike(name: String, file: String = __FILE__, line: Int = __LINE__) {
    itBehavesLike(name, { return [:] }, file: file, line: line)
}

/**
    Inserts the examples defined using a `sharedExamples` function into the current example group.
    The shared examples are executed at this location, as if they were written out manually.
    This function also passes those shared examples a context that can be evaluated to give the shared
    examples extra information on the subject of the example.

    :param: name The name of the shared examples group to be executed. This must be identical to the
                 name of a shared examples group defined using `sharedExamples`. If there are no shared
                 examples that match the name given, an exception is thrown and the test suite will crash.
    :param: sharedExampleContext A closure that, when evaluated, returns key-value pairs that provide the
                                 shared examples with extra information on the subject of the example.
    :param: file The absolute path to the file containing the current example group. A sensible default is provided.
    :param: line The line containing the current example group. A sensible default is provided.
*/
public func itBehavesLike(name: String, sharedExampleContext: SharedExampleContext, file: String = __FILE__, line: Int = __LINE__) {
    World.sharedWorld().itBehavesLike(name, sharedExampleContext: sharedExampleContext, file: file, line: line)
}

/**
    Defines an example or example group that should not be executed. Use `pending` to temporarily disable
    examples or groups that should not be run yet.

    :param: description An arbitrary string describing the example or example group.
    :param: closure A closure that will not be evaluated.
*/
public func pending(description: String, closure: () -> ()) {
    World.sharedWorld().pending(description, closure: closure)
}

/**
    Identical to `pending`. Use this to quickly disable a `describe` closure.
*/
public func xdescribe(description: String, closure: () -> ()) {
    pending(description, closure)
}

/**
    Identical to `pending`. Use this to quickly disable a `context` closure.
*/
public func xcontext(description: String, closure: () -> ()) {
    pending(description, closure)
}

/**
    Identical to `pending`. Use this to quickly disable a `it` closure.
*/
public func xit(description: String, closure: () -> ()) {
    pending(description, closure)
}
