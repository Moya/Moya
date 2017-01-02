import Quick
import Nimble
@testable import Moya

class MultiPartFormData: QuickSpec {
    override func spec() {
        it("initializes correctly") {
            let fileURL = URL(fileURLWithPath: "/tmp.txt")
            let data = MultipartFormData(
                provider: .file(fileURL),
                name: "MyName",
                fileName: "tmp.txt",
                mimeType: "text/plain"
            )

            expect(data.name) == "MyName"
            expect(data.fileName) == "tmp.txt"
            expect(data.mimeType) == "text/plain"

            if case .file(let url) = data.provider {
                expect(url) == fileURL
            } else {
                fail("The provider was not initialized correctly.")
            }
        }
    }
}
