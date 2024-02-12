# red-vpn


## Building - Android

```
$ git clone --recurse-submodules https://github.com/ProminentEdge/red-vpn
$ cd red-vpn
$ cd android
$ ./gradlew assembleRelease
```

---

## fastlane
* Keytool was generated with `keytool` cli.
* Keystore file, and keystore password information are in 1password "tools" vault.
* Update .env.example with proper password values; they are the same.

### Setup:

* Install [brew from this link](https://brew.sh/)
* Install yarn:

* You must install java prior to version 1.10 as the latest versions output a differently formatted string and break the latest fastlane code.
* Please use the official site to find disable / uninstall instructions for built-in java, and to re-install the Java JDK / JRE SE for versions 8 and lower.
* [Java Downloads](https://www.oracle.com/technetwork/java/javase/downloads/index.html).

* Install gradle:
```
brew install gradle
```

* Install fastlane:
```
brew cask install fastlane

# Now update your ~/.bashrc or ~/.bash_profile scripts:
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export PATH="$HOME/.fastlane/bin:$PATH"
```

* Install android sdk and android ndk:
```
brew tap homebrew/cask
brew cask install android-sdk
brew cask install android-ndk
```

#### Android Installation

* You can try through the official Android Studio [download here](https://www.androidcentral.com/installing-android-sdk-windows-mac-and-linux-tutorial)

* You can also follow [this guy](https://gist.github.com/patrickhammond/4ddbe49a67e5eb1b9c03), but the following steps do not follow these instructions in totality.

##### NOTE - these instructions are for the brew-based installation of the android sdk.

* Get the information for the recently installed `android-sdk` package (from above).
```
brew cask info android-sdk
```

* Now update your ~/.bash_profile again:
```
export ANDROID_HOME="/usr/local/Caskroom/android-sdk/4333796/" # the numbers at the end should changed based on your brew installation.
export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"

export PATH="$HOME/Android/tools:$PATH"
export PATH="$HOME/Android/platform-tools:$PATH"
```

* Now install sdkmanager packages
```
$ANDROID_HOME/tools/bin/sdkmanager "platforms;android-27"
$ANDROID_HOME/tools/bin/sdkmanager "build-tools;27.0.3"
```

## Signing:

[signing instructions for android](https://facebook.github.io/react-native/docs/signed-apk-android)

* This has already done and default variables for an anonymous user were added to `android/gradle.properties`, and the keystore file added to `android/app`.

## Run:

```
yarn install
fastlane android apk 
```
