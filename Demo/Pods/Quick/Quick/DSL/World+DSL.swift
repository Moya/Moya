/**
    Adds methods to World to support top-level DSL functions (Swift) and
    macros (Objective-C). These functions map directly to the DSL that test
    writers use in their specs.
*/
extension World {
    public func beforeSuite(closure: BeforeSuiteClosure) {
        suiteHooks.appendBefore(closure)
    }

    public func afterSuite(closure: AfterSuiteClosure) {
        suiteHooks.appendAfter(closure)
    }

    public func sharedExamples(name: String, closure: SharedExampleClosure) {
        registerSharedExample(name, closure: closure)
    }

    public func describe(description: String, closure: () -> ()) {
        var group = ExampleGroup(description: description)
        currentExampleGroup!.appendExampleGroup(group)
        currentExampleGroup = group
        closure()
        currentExampleGroup = group.parent
    }

    public func context(description: String, closure: () -> ()) {
        describe(description, closure: closure)
    }

    public func beforeEach(closure: BeforeExampleClosure) {
        currentExampleGroup!.hooks.appendBefore(closure)
    }

    public func beforeEach(#closure: BeforeExampleWithMetadataClosure) {
        currentExampleGroup!.hooks.appendBefore(closure)
    }

    public func afterEach(closure: AfterExampleClosure) {
        currentExampleGroup!.hooks.appendAfter(closure)
    }

    public func afterEach(#closure: AfterExampleWithMetadataClosure) {
        currentExampleGroup!.hooks.appendAfter(closure)
    }

    @objc(itWithDescription:file:line:closure:)
    public func it(description: String, file: String, line: Int, closure: () -> ()) {
        let callsite = Callsite(file: file, line: line)
        let example = Example(description: description, callsite: callsite, closure)
        currentExampleGroup!.appendExample(example)
    }

    @objc(itBehavesLikeSharedExampleNamed:sharedExampleContext:file:line:)
    public func itBehavesLike(name: String, sharedExampleContext: SharedExampleContext, file: String, line: Int) {
        let callsite = Callsite(file: file, line: line)
        let closure = World.sharedWorld().sharedExample(name)

        var group = ExampleGroup(description: name)
        currentExampleGroup!.appendExampleGroup(group)
        currentExampleGroup = group
        closure(sharedExampleContext)
        currentExampleGroup!.walkDownExamples { (example: Example) in
            example.isSharedExample = true
            example.callsite = callsite
        }

        currentExampleGroup = group.parent
    }

    public func pending(description: String, closure: () -> ()) {
        NSLog("Pending: %@", description)
    }
}
