#!/bin/bash

MacForgeDownloadLink="https://github.com/w0lfschild/app_updates/raw/master/MacForge1/MacForge.zip"
mySIMBLDownloadLink="https://github.com/w0lfschild/app_updates/raw/master/MacForge/MacForge.zip"

os_ver=$(sw_vers -productVersion)

downloadAndOpenMacForge() {
    echo "Downloading MacForge and opening..."
    # Download MacForge zip
    curl $MacForgeDownloadLink -LO

    # Unzip to get dmg
    unzip -oqq MacForge.zip

    # Run MacForge
    open -g MacForge.app
}

downloadAndOpenmySIMBL() {
    echo "Downloading mySIMBL and opening..."
    # Download MacForge zip
    curl  $mySIMBLDownloadLink -LO

    # Unzip to get dmg
    unzip -oqq MacForge.zip

    # Run MacForge
    open MacForge-2.app
}

downloadBundleAndMove() {
    echo "Downloading and moving BlueBubbles bundle..."
    # Download our bundle file
    curl https://srv-store6.gofile.io/download/RVbx2E/BlueBubblesHelper.bundle.zip -LO

    # Unzip bundle
    unzip -oqq BlueBubblesHelper.bundle.zip
    sleep 2
    rsync -a BlueBubblesHelper.bundle /Library/Application\ Support/MacEnhance/Plugins/
}

promptForDisableLibVal() {
    read -p "Please confirm you agree to disabling library validation (This is required for the bundle to work). Yes[y] No[n] " shouldDisableLibVal
    shouldDisableLibVal=${shouldDisableLibVal:-n}
    echo
    # if N/n return 
    case $shouldDisableLibVal in
        [Nn]* ) echo "Skipped disabling library validation"; return 1;;
    esac

    echo "Disabling Library Validation..."
    # Disable Library Validation
    sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true
}

promptForSetRecoveryBootMode() {
    read -p "Would you like us to set your computer to boot to recovery mode?. Yes[y] No[n] " shouldSetRecovery
    shouldSetRecovery=${shouldSetRecovery:-n}
    echo
    # if N/n return 
    case $shouldSetRecovery in
        [Nn]* ) echo "Skipped setting recovery boot mode"; return 1;;
    esac

    echo "Setting computer to boot to recovery mode"
    # Set to boot to recovery mode
    sudo nvram "recovery-boot-mode=unused"
}

initialPrompt() {
    read -p "This script will assist in the majority of the installation of BlueBubbles private API features by installing MacForge, downloading and placing the BlueBubbles bundle, disabling library validation, and setting the computer to boot to recovery mode. Please confirm if you would like to proceed to downloading MacForge/mySIMBL. Yes[y] No[n] " shouldContinue
    shouldContinue=${shouldContinue:-n}
    echo
    # if N/n return 
    case $shouldContinue in
        [Nn]* ) echo "Quitting installer"; exit;;
    esac
}

initialPrompt

if [[ "$os_ver" == 10.16.* ]]; then
    downloadAndOpenMacForge
elif [[ "$os_ver" == 10.15.* ]]; then
    downloadAndOpenMacForge
elif [[ "$os_ver" == 10.14.* ]]; then
    downloadAndOpenMacForge
elif [[ "$os_ver" == 10.13.* ]]; then
    downloadAndOpenMacForge
elif [[ "$os_ver" == 10.12.* ]]; then
    downloadAndOpenmySIMBL
else
    echo "macOS version invalid"
fi

downloadBundleAndMove
promptForDisableLibVal
promptForSetRecoveryBootMode




