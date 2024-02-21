import Quick
import Nimble
import Foundation

@testable import Moya

final class MultiPartFormData: QuickSpec {
    override func spec() {
        it("initializes correctly") {
            let fileURL = URL(fileURLWithPath: "/tmp.txt")
            let bodyPart = MultipartFormBodyPart(
                provider: .file(fileURL),
                name: "MyName",
                fileName: "tmp.txt",
                mimeType: "text/plain"
            )
            let data = MultipartFormData(parts: [bodyPart])

            expect(data.boundary).to(beNil())
            expect(data.fileManager) == FileManager.default
            expect(data.parts.count) == 1
            expect(data.parts[0].name) == "MyName"
            expect(data.parts[0].fileName) == "tmp.txt"
            expect(data.parts[0].mimeType) == "text/plain"

            if case .file(let url) = data.parts[0].provider {
                expect(url) == fileURL
            } else {
                fail("The provider was not initialized correctly.")
            }
        }
    }
}
