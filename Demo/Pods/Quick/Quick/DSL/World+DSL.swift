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

    public func describe(description: String, flags: FilterFlags, closure: () -> ()) {
        var group = ExampleGroup(description: description, flags: flags)
        currentExampleGroup!.appendExampleGroup(group)
        currentExampleGroup = group
        closure()
        currentExampleGroup = group.parent
    }

    public func context(description: String, flags: FilterFlags, closure: () -> ()) {
        self.describe(description, flags: flags, closure: closure)
    }

    public func fdescribe(description: String, flags: FilterFlags, closure: () -> ()) {
        var focusedFlags = flags
        focusedFlags[Filter.focused] = true
        self.describe(description, flags: focusedFlags, closure: closure)
    }

    public func xdescribe(description: String, flags: FilterFlags, closure: () -> ()) {
        var pendingFlags = flags
        pendingFlags[Filter.pending] = true
        self.describe(description, flags: pendingFlags, closure: closure)
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

    @objc(itWithDescription:flags:file:line:closure:)
    public func it(description: String, flags: FilterFlags, file: String, line: Int, closure: () -> ()) {
        let callsite = Callsite(file: file, line: line)
        let example = Example(description: description, callsite: callsite, flags: flags, closure: closure)
        currentExampleGroup!.appendExample(example)
    }

    @objc(fitWithDescription:flags:file:line:closure:)
    public func fit(description: String, flags: FilterFlags, file: String, line: Int, closure: () -> ()) {
        var focusedFlags = flags
        focusedFlags[Filter.focused] = true
        self.it(description, flags: focusedFlags, file: file, line: line, closure: closure)
    }

    @objc(xitWithDescription:flags:file:line:closure:)
    public func xit(description: String, flags: FilterFlags, file: String, line: Int, closure: () -> ()) {
        var pendingFlags = flags
        pendingFlags[Filter.pending] = true
        self.it(description, flags: pendingFlags, file: file, line: line, closure: closure)
    }

    @objc(itBehavesLikeSharedExampleNamed:sharedExampleContext:flags:file:line:)
    public func itBehavesLike(name: String, sharedExampleContext: SharedExampleContext, flags: FilterFlags, file: String, line: Int) {
        let callsite = Callsite(file: file, line: line)
        let closure = World.sharedWorld().sharedExample(name)

        var group = ExampleGroup(description: name, flags: flags)
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
        println("Pending: \(description)")
    }
}
