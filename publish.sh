echo "📦  Updating Swift packages..."
swift package update
swift package resolve

echo "📦  Determining latest Git tag..."
TAG=$(git describe --abbrev=0 --tags);

echo "📦  Building..."
swift build -c release -Xswiftc -static-stdlib

echo "📦  Creating package..."
EXEC_NAME="ether"
PACKAGE_NAME="ether-$TAG"
mkdir -p ./$PACKAGE_NAME

README="./$PACKAGE_NAME/README.txt"

echo "Manual Install Instructions for Ether v$TAG" > $README
echo "" >> $README
echo "- Move *.dylib files into /usr/local/lib" >> $README
echo "- Move executable $EXEC_NAME into /usr/local/bin" >> $README
echo "- Type '$EXEC_NAME --help' into terminal to verify installation" >> $README

cp .build/release/Executable ./$PACKAGE_NAME/$EXEC_NAME

tar -cvzf macOS-sierra.tar.gz ./$PACKAGE_NAME

echo "📦  Drag and drop $PWD/macOS-sierra.tar.gz into https://github.com/vapor/toolbox/releases/edit/$TAG"

while true; do
    read -p "Have you finished uploading? [y/n]" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

rm -rf macOS-sierra.tar.gz
rm -rf $PACKAGE_NAME
