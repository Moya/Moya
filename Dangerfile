# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
not_declared_trivial = !(github.pr_title.include? "#trivial")
has_app_changes = !git.modified_files.grep(/Sources/).empty?

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "WIP"

# Warn, asking to update Chinese docs if only English docs are updated and vice-versa
en_docs_modified = git.modified_files.grep(%r{docs/}).empty? # Necessary to exclude `docs_CN` from the grep.
cn_docs_modified = git.modified_files.grep(%r{docs_CN}).empty?
if en_docs_modified ^ cn_docs_modified
  warn("Consider **also** updating the #{ en_docs_modified ? "English" : "Chinese" } docs. For Chinese translations, request the modified file(s) to be added to the list [here](https://github.com/Moya/Moya/issues/1357) for someone else to translate, if you can't do so yourself.")
end

# Warn, asking to update Chinese README if only English README are updated and vice-versa
en_readme_modified = !git.modified_files.grep(%r{Readme.md}).empty?
cn_readme_modified = !git.modified_files.grep(%r{Readme_CN.md}).empty?
if en_readme_modified ^ cn_readme_modified
  warn("Consider **also** updating the #{ en_readme_modified ? "Chinese" : "English" } README. For Chinese translations, request the modified file(s) to be added to the list [here](https://github.com/Moya/Moya/issues/1357) for someone else to translate, if you can't do so yourself.")
end

# Warn when there is a big PR
warn("Big PR, try to keep changes smaller if you can") if git.lines_of_code > 500

# Don't let testing shortcuts get into master by accident
fail("fit left in tests") if `grep -r "fit Demo/Tests/ `.length > 1

# Changelog entries are required for changes to library files.
no_changelog_entry = !git.modified_files.include?("Changelog.md")
if has_app_changes && no_changelog_entry && not_declared_trivial
  warn("Any changes to library code should be reflected in the Changelog. Please consider adding a note there and adhere to the [Changelog Guidelines](https://github.com/Moya/contributors/blob/master/Changelog%20Guidelines.md).")
end

# Added (or removed) library files need to be added (or removed) from the
# Carthage Xcode project to avoid breaking things for our Carthage users.
added_swift_library_files = !(git.added_files.grep(/Sources.*\.swift/).empty?)
deleted_swift_library_files = !(git.deleted_files.grep(/Sources.*\.swift/).empty?)
modified_carthage_xcode_project = !(git.modified_files.grep(/Moya\.xcodeproj/).empty?)
if (added_swift_library_files || deleted_swift_library_files) && !modified_carthage_xcode_project
  fail("Added or removed library files require the Carthage Xcode project to be updated. See the Readme")
end

missing_doc_changes = git.modified_files.grep(/docs/).empty?
doc_changes_recommended = git.insertions > 15
if has_app_changes && missing_doc_changes && doc_changes_recommended && not_declared_trivial
  warn("Consider adding supporting documentation to this change. Documentation can be found in the `docs` directory.")
end

# Wrapper for package manifest file name and update status
PackageManifest = Struct.new(:fileName, :updated)

# Well formatted, comma separated list of package manifest(s)
def format_manifests(manifests)
    return "" if manifests.empty?
    formatted = manifests.map { |e| "`#{e.fileName}`" }
    return formatted.first if formatted.size == 1
    output = formatted.join(', ')
    output[output.rindex(',')] = ' and'
    return output
end

# Warning message for not updated package manifest(s)
def manifests_warning_message(updated:, not_updated:)
    return "Unable to construct warning message." if updated.empty? || not_updated.empty?
    updated_manifests_names = format_manifests(updated)
    not_updated_manifests_names = format_manifests(not_updated)
    updated_article = updated.size == 1 ? "The " : ""
    updated_verb = updated.size == 1 ? "was" : "were"
    not_updated_article = not_updated.size == 1 ? "the " : ""
    output = "#{updated_article}#{updated_manifests_names} #{updated_verb} updated, " \
             "but there were no changes in #{not_updated_article}#{not_updated_manifests_names}.\n"\
             "Did you forget to update #{not_updated_manifests_names}?"
    return output
end

# Warn when any of the package manifest(s) updated but not others
podspec_updated = PackageManifest.new("Moya.podspec", !git.modified_files.grep(/Moya.podspec/).empty?)
cartfile_updated = PackageManifest.new("Cartfile", !git.modified_files.grep(/Cartfile$/).empty?)
cartfile_resolved_updated = PackageManifest.new("Cartfile.resolved", !git.modified_files.grep(/Cartfile.resolved/).empty?)
package_updated = PackageManifest.new("Package.swift", !git.modified_files.grep(/Package.swift/).empty?)
package_resolved_updated = PackageManifest.new("Package.resolved", !git.modified_files.grep(/Package.resolved/).empty?)

manifests = [
    podspec_updated, 
    cartfile_updated, 
    cartfile_resolved_updated,
    package_updated,
    package_resolved_updated
]

updated_manifests = manifests.select { |e| e.updated }
not_updated_manifests = manifests.select { |e| !e.updated }

if !updated_manifests.empty? && !not_updated_manifests.empty?
    warn(manifests_warning_message(updated: updated_manifests, not_updated: not_updated_manifests))
end

# Warn when library files has been updated but not tests.
tests_updated = !git.modified_files.grep(/Tests/).empty?
if has_app_changes && !tests_updated
  warn("The library files were changed, but the tests remained unmodified. Consider updating or adding to the tests to match the library changes.")
end

# Run SwiftLint
swiftlint.lint_files

# Xcode summary
def config_xcode_summary() 
  xcode_summary.ignored_results { |result|
    result.message.start_with?("ld") # Ignore ld_warnings
  }
end 

def summary(platform:)
  xcode_summary.report "xcodebuild-#{platform}.json"
end

def label_tests_summary(label:, platform:) 
  file_name = "xcodebuild-#{platform}.json"
  json = File.read(file_name)
  data = JSON.parse(json)
  data["tests_summary_messages"].each { |message| 
    if !message.empty?
      message.insert(1, " " + label + ":")
    end
  }
  File.open(file_name,"w") do |f|
    f.puts JSON.pretty_generate(data)
  end 
end

config_xcode_summary()

label_tests_summary(label: "iOS", platform: "ios")
label_tests_summary(label: "tvOS", platform: "tvos")
label_tests_summary(label: "macOS", platform: "macos")

summary(platform: "ios")
summary(platform: "tvos")
summary(platform: "macos")
