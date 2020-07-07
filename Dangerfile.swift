import Danger
import DangerSwiftProse // package: https://github.com/f-meloni/danger-swift-prose.git
import DangerXCodeSummary // package: https://github.com/f-meloni/danger-swift-xcodesummary.git
import Foundation

let danger = Danger()

let github = danger.github

// Changelog entries are required for changes to library files.
let allSourceFiles = danger.git.modifiedFiles + danger.git.createdFiles
let noChangelogEntry = !allSourceFiles.contains("Changelog.md")
let sourceChanges = allSourceFiles.contains { $0.hasPrefix("Sources") }
let isNotTrivial = !danger.github.pullRequest.title.contains("#trivial")
if isNotTrivial && noChangelogEntry && sourceChanges {
    danger.warn("""
         Any changes to library code should be reflected in the Changelog.
         Please consider adding a note there and adhere to the [Changelog Guidelines](https://github.com/Moya/contributors/blob/master/Changelog%20Guidelines.md).
        """)
}

// Make it more obvious that a PR is a work in progress and shouldn't be merged yet
if danger.github.pullRequest.title.contains("WIP") {
    warn("PR is classed as Work in Progress")
}

// Warn, asking to update Chinese docs if only English docs are updated and vice-versa
let enDocsModified = danger.git.modifiedFiles.contains { $0.contains("docs/") }
let cnDocsModified = danger.git.modifiedFiles.contains { $0.contains("docs_CN/") }
if (enDocsModified && !cnDocsModified) || (!enDocsModified && cnDocsModified) {
    warn("Consider **also** updating the \(enDocsModified ? "Chinese" : "English") docs. For Chinese translations, request the modified file(s) to be added to the list [here](https://github.com/Moya/Moya/issues/1357) for someone else to translate, if you can't do so yourself.")
}

// Warn, asking to update Chinese README if only English README are updated and vice-versa
let enReameModified = danger.git.modifiedFiles.contains { $0.contains("Readme.md") }
let chReameModified = danger.git.modifiedFiles.contains { $0.contains("Readme_CN.md") }
if (enReameModified && !chReameModified) || (!enReameModified && chReameModified) {
    warn("Consider **also** updating the \(enReameModified ? "Chinese" : "English") README. For Chinese translations, request the modified file(s) to be added to the list [here](https://github.com/Moya/Moya/issues/1357) for someone else to translate, if you can't do so yourself.")
}

// Warn when there is a big PR
if (danger.github.pullRequest.additions ?? 0) > 500 {
    warn("Big PR, try to keep changes smaller if you can")
}

// Don't let testing shortcuts get into master by accident
if danger.utils.exec("grep -r \"fit Demo/Tests/\"").count > 1 {
    fail("fit left in tests")
}

// Added (or removed) library files need to be added (or removed) from the
// Xcode project to avoid breaking things for our Carthage/manual framework.
let addedSwiftLibraryFiles = danger.git.createdFiles.contains { $0.fileType == .swift && $0.hasPrefix("Sources") }
let deletedSwiftLibraryFiles = danger.git.deletedFiles.contains { $0.fileType == .swift && $0.hasPrefix("Sources") }
let modifiedCarthageXcodeProject = danger.git.modifiedFiles.contains { $0.contains("Moya.xcodeproj") }
if (addedSwiftLibraryFiles || deletedSwiftLibraryFiles) && !modifiedCarthageXcodeProject {
    fail("Added or removed library files require the Carthage Xcode project to be updated. See the Readme")
}

let missingDocChanges = !danger.git.modifiedFiles.contains { $0.contains("docs") }
let docChangeRecommended = (danger.github.pullRequest.additions ?? 0) > 15
if sourceChanges && missingDocChanges && docChangeRecommended && isNotTrivial {
    warn("Consider adding supporting documentation to this change. Documentation can be found in the `docs` directory.")
}

// Run danger-prose to lint Chinese docs
let addedAndModifiedCnDocsMarkdown = allSourceFiles.filter { $0.fileType == .markdown && $0.contains("docs_CN") }
if #available(OSX 10.12, *),
    !addedAndModifiedCnDocsMarkdown.isEmpty {
    Proselint.performSpellCheck(files: addedAndModifiedCnDocsMarkdown, excludedRules: ["misc.scare_quotes", "typography.symbols"])
}

// Run danger-prose to lint and check spelling English docs
let addedAndModifiedEnDocsMarkdown = allSourceFiles.filter { $0.fileType == .markdown && $0.contains("docs/") }
if #available(OSX 10.12, *),
    !addedAndModifiedEnDocsMarkdown.isEmpty {
    Proselint.performSpellCheck(files: addedAndModifiedEnDocsMarkdown)

    let ignoredWords = ["Auth", "auth", "Moya", "enum", "enums", "OAuth", "Artsy's", "Heimdallr.swift", "SwiftyJSONMapper", "ObjectMapper", "Argo", "ModelMapper", "ReactiveSwift", "RxSwift", "multipart", "JSONEncoder", "Alamofire", "CocoaPods", "URLSession", "plugin", "plugins", "stubClosure", "requestClosure", "endpointClosure", "Unsplash", "ReactorKit", "Dribbble", "EVReflection", "Unbox"]
    Mdspell.performSpellCheck(files: addedAndModifiedEnDocsMarkdown, ignoredWords: ignoredWords, language: "en-us")
}

// Warning message for not updated package manifest(s)
let manifests = [
    "Moya.podspec",
    "Cartfile",
    "Cartfile.resolved",
    "Package.swift",
    "Package.resolved"
]
let updatedManifests = manifests.filter { manifest in danger.git.modifiedFiles.contains { $0.name == manifest } }
if !updatedManifests.isEmpty && updatedManifests.count != manifests.count {
    let notUpdatedManifests = manifests.filter { !updatedManifests.contains($0) }
    let updatedArticle = updatedManifests.count == 1 ? "The " : ""
    let updatedVerb = updatedManifests.count == 1 ? "was" : "were"
    let notUpdatedArticle = notUpdatedManifests.count == 1 ? "the " : ""

    warn("\(updatedArticle)\(updatedManifests.joined(separator: ", ")) \(updatedVerb) updated, " +
        "but there were no changes in \(notUpdatedArticle)\(notUpdatedManifests.joined(separator: ", ")).\n" +
        "Did you forget to update them?")
}

// Warn when library files has been updated but not tests.
let testsUpdated = danger.git.modifiedFiles.contains { $0.hasPrefix("Tests") }
if sourceChanges && !testsUpdated {
    warn("The library files were changed, but the tests remained unmodified. Consider updating or adding to the tests to match the library changes.")
}

// Run Swiftlint
SwiftLint.lint(inline: true, configFile: ".swiftlint.yml")

// Xcode summary
func filePathForPlatform(_ platform: String) -> String {
    return "xcodebuild-\(platform).json"
}
func labelTestSummary(label: String, platform: String) throws {
    let file = filePathForPlatform(platform)
    let json = danger.utils.readFile(file)

    guard let data = json.data(using: .utf8),
        var jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
        throw CocoaError(.fileReadCorruptFile)
    }

    jsonDictionary["tests_summary_messages"] = (jsonDictionary["tests_summary_messages"] as? [String])?.map { label + ": " + $0 }
    try String(data: JSONSerialization.data(withJSONObject: jsonDictionary, options: []), encoding: .utf8)?.write(toFile: file, atomically: false, encoding: .utf8)
}
func summary(platform: String) {
    XCodeSummary(filePath: filePathForPlatform(platform)).report()
}

try labelTestSummary(label: "iOS", platform: "ios")
try labelTestSummary(label: "tvOS", platform: "tvos")
try labelTestSummary(label: "macOS", platform: "macos")

summary(platform: "ios")
summary(platform: "tvos")
summary(platform: "macos")
