Releasing
=========

(Note: This document is a reference for people with push access to Moya and to [CocoaPods](https://cocoapods.org/pods/Moya).)

Releasing a new version of Moya has been automated as much as possible. There are a few prerequisite steps:

1. [Generate a GitHub personal access token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/)
1. Run the following command: `echo "machine api.github.com login you@yourgithublogin.com password THE_BRAND_NEW_TOKEN" > ~/.netrc`. This lets the automated release script access the GitHub API authorized as you.
1. Then run `chmod 600 ~/.netrc`.
1. Make sure you have a registered CocoaPods session (run `pod trunk register you@youremailaddress.com` to make one if not).


Note: to make a release, you need at least one entry in the `Next` section of the changelog.

To make a release:

1. Pull latest from master and make sure your git is clean (the script will fail if it's not).
1. Run `rake release["X.Y.Z"]`.
1. Grab a :tea: or :coffee:.
1. Make sure everything went smoothly.

What you'll need to do manually afterwards (if you released a major version):

1. Update the Swift Package Manager instructions in the Readme to use the release you just made public.

If anything goes wrong, don't panic! Get in touch with someone else who has released, or [Ash](mailto:ash@ashfurrow.com).
