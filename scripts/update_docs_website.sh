git clone git@github.com:Moya/moya.github.io.git _moya.github.io

# These two lines, instead of pure `jazzy -o ...` make sure we consistently produce docs
# Otherwise we would sometimes get empty docs due to some cache bug & new Xcode file response
# Relevant: https://github.com/realm/jazzy/issues/1087
rm -rf ~/Library/Developer/Xcode/DerivedData/Moya*
jazzy --documentation=docs/*.md -x USE_SWIFT_RESPONSE_FILE=NO -o _moya.github.io

cd _moya.github.io

git add .

git commit -m "Update docs for version $VERSION"

git push origin HEAD

cd ..

rm -rf _moya.github.io
