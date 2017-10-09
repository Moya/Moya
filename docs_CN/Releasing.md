# 发布

(_Note: This document is a reference for people with push access to Moya and to [CocoaPods](https://cocoapods.org/pods/Moya)._)

## Before release

Releasing a new version of Moya has been automated as much as possible. There are a few prerequisite steps:

1. [Generate a GitHub personal access token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/)
1. Run the following command: 
```ruby
echo "machine api.github.com login {GITHUB_LOGIN} password {GITHUB_TOKEN}" > ~/.netrc
``` 
Where `{GITHUB_LOGIN}` is your GitHub login and `{GITHUB_TOKEN}` is your personal access token generated in step 1 (or if you had one before). Example:
```ruby
echo "machine api.github.com login ashfurrow password dc14e6ac2b871e7630f56df3d57d2694b576316a" > ~/.netrc
```
This lets the automated release script access the GitHub API authorized as you.
1. Then run `chmod 600 ~/.netrc`.
1. Make sure you have a registered CocoaPods session. To do that you can run command:
```ruby
pod trunk me
```
If you see an error command that you do not have registered session, run command below:
```ruby
pod trunk register you@youremailaddress.com
```

## Release

(_Note: To make a release, you need at least one entry in the `Next` section of the changelog._)

To make a release:

1. Pull latest from master and make sure your git is clean (the script will fail if it's not).
1. Run `rake release["X.Y.Z"]`. (If you use ZSH, use `rake release\["X.Y.Z"\]`)
1. Grab a :tea: or :coffee:.
1. Make sure everything went smoothly.

What you'll need to do manually afterwards (if you released a major version):

1. Update the Swift Package Manager instructions in the Readme to use the release you just made public.

If anything goes wrong, don't panic! Get in touch with someone else who has released, or [Ash](mailto:ash@ashfurrow.com).
