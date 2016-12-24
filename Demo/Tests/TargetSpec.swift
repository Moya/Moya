import Quick
import Nimble
@testable import Moya

class TargetSpec: QuickSpec {
    override func spec() {
        describe("a SingleURLTarget") {
            it("initializes correctly with defaults") {
                let url = URL(string: "http://api.com")!
                let target = SingleURLTarget(url: url)
                expect(target.baseURL).to(equal(url))
                expect(target.path).to(equal(""))
                expect(target.method).to(equal(Method.get))
                expect(target.parameters).to(beNil())
                expect(target.parameterEncoding is URLEncoding).to(equal(true))
                expect(target.sampleData).to(equal(Data()))
                expect(String(describing: target.task)).to(equal("request")) // This is a hack to avoid implementing Equatable for Task
                expect(target.validate).to(equal(false))
            }
        }
    }
}
