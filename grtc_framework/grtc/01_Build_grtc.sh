#!bin/bash --login

# 1. Build for iphoneos
xcodebuild archive -scheme "grtc" -archivePath "./build/ios.xcarchive" -sdk iphoneos SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# 2. Build for simulator
xcodebuild archive -scheme "grtc" -archivePath "./build/ios_sim.xcarchive" -sdk iphonesimulator SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# 3. Build xcframework
xcodebuild -create-xcframework -framework ./build/ios.xcarchive/Products/Library/Frameworks/grtc.framework -framework ./build/ios_sim.xcarchive/Products/Library/Frameworks/grtc.framework -output ./build/grtc.xcframework
