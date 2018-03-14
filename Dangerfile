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

# Warn when either the podspec or Cartfile + Cartfile.resolved has been updated,
# but not both.
podspec_updated = !git.modified_files.grep(/Moya.podspec/).empty?
cartfile_updated = !git.modified_files.grep(/Cartfile/).empty?
cartfile_resolved_updated = !git.modified_files.grep(/Cartfile.resolved/).empty?

if podspec_updated && (!cartfile_updated || !cartfile_resolved_updated)
  warn("The `podspec` was updated, but there were no changes in either the `Cartfile` nor `Cartfile.resolved`. Did you forget updating `Cartfile` or `Cartfile.resolved`?")
end

if (cartfile_updated || cartfile_resolved_updated) && !podspec_updated
  warn("The `Cartfile` or `Cartfile.resolved` was updated, but there were no changes in the `podspec`. Did you forget updating the `podspec`?")
end

# Warn when library files has been updated but not tests.
tests_updated = !git.modified_files.grep(/Tests/).empty?
if has_app_changes && !tests_updated
  warn("The library files were changed, but the tests remained unmodified. Consider updating or adding to the tests to match the library changes.")
end

# Run SwiftLint
swiftlint.lint_files
