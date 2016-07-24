# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
not_declared_trivial = !(github.pr_title.include? "#trivial")
has_app_changes = !git.modified_files.grep(/Source/).empty?

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("Big PR") if lines_of_code > 500

# Don't let testing shortcuts get into master by accident
fail("fit left in tests") if `grep -r "fit Demo/Tests/ `.length > 1

# Changelog entries are required for changes to library files.
no_changelog_entry = !git.modified_files.include?("Changelog.md")
if has_app_changes && no_changelog_entry && not_declared_trivial
  fail("Any changes to library code need a summary in the Changelog.")
end

added_swift_library_files = git.modified_files.grep(/Source.*\.swift/).empty?
deleted_swift_library_files = git.deleted_files.grep(/Source.*\.swift/).empty?
modified_carthage_xcode_project = !(git.deleted_files.grep(/Moya\.xcodeproj/).empty?)
if (added_swift_library_files || deleted_swift_library_files) && modified_carthage_xcode_project
  fail("Added or removed library files require the Carthage Xcode project to be updated.")
end

# Run SwiftLint
swiftlint.lint_files
