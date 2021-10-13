## BlueBubbles Helper Bundle (Private API)

This is the repo for the bundle containing code to perform various tasks not accessible through Apple's AppleScript, for example sending tapbacks or typing indicators.

### Features

- Send reactions
- Send and receive typing indicators
- Mark chats read on the server Mac
- Rename group chats
- Add / remove participants from group chats
- Send replies
- Send message effects
- Send message with subject
- Update pinned chats on the server Mac

### Support

The bundle has been tested on MacOS 10.13 (High Sierra) - MacOS 11 (Big Sur). It could work on higher or lower MacOS versions, but we do not know for sure.

### Build Yourself

#### Pre-requirements:

1. MacOS and Xcode
2. Apple Developer account with a valid Team ID
3. **10.12 - 10.13**: [mySIMBL](https://github.com/w0lfschild/mySIMBL/releases) / **10.14+**: [MacForge](https://www.macenhance.com/macforge)

#### Instructions:

1. Clone the repo and open the respective folder for your macOS version, then open the Xcode project in Xcode
2. Hit the Play button and you're done! This will automatically build the `.bundle` and install it in the MacForge / mySIMBL directory.

### Develop

Its recommended have a good knowledge of Objective-C and tweak development before attempting to develop just to make things easier on yourself :)

#### Resources

1. https://iphonedev.wiki/index.php/Main_Page - tweak development wiki
2. https://github.com/w0lfschild/macOS_headers - pre-dumped headers for macOS
3. https://github.com/open-imcore/barcelona - Eric Rabil's wonderful REST API built using IMCore
4. https://github.com/limneos/classdump-dyld (OS X) / https://github.com/freedomtan/classdump-dyld/ (Big Sur) - scripts to dump headers on macOS
5. ZKSwizzle

Use the above resources and trial and error to develop new IMCore integrations! There aren't any Apple provided docs of course, so there is a lot of educated guesswork and using the above resources to try and add things to the bundle. If stuff doesn't work, don't give up! Find as many clues as you can by searching online, searching the header files, and using swizzling techniques.
