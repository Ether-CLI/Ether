git clone https://github.com/calebkleveter/Ether.git
cd Ether
swift build -c release -Xswiftc -static-stdlib
cp -f .build/release/Executable /usr/local/bin/ether
cd ../
rm -rf Ether/
mkdir ~/Library/Application\ Support/Ether
mkdir ~/Library/Application\ Support/Ether/Templates
