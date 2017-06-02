# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
not_declared_trivial = !(github.pr_title.include? "#trivial")
has_app_changes = !git.modified_files.grep(/Sources/).empty?

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("Big PR, try to keep changes smaller if you can") if git.lines_of_code > 500

# Don't let testing shortcuts get into master by accident
fail("fit left in tests") if `grep -r "fit Demo/Tests/ `.length > 1

# Changelog entries are required for changes to library files.
no_changelog_entry = !git.modified_files.include?("Changelog.md")
if has_app_changes && no_changelog_entry && not_declared_trivial
  warn("Any changes to library code should be reflected in the Changelog. Please consider adding a note there.")
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

# Run SwiftLint
swiftlint.lint_files
