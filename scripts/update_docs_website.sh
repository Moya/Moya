git clone git@github.com:Moya/moya.github.io.git _moya.github.io

jazzy -o _moya.github.io

cd _moya.github.io

git add .

git commit -m "Update docs for version $VERSION"

git push origin HEAD

cd ..

rm -rf _moya.github.io
