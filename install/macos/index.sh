#!/bin/bash

# Helper: Display popup with Open and Done buttons
# $1 = Message, $2 = command to run
popup() {
  osascript -e '
    on run argv
      set dialogText to item 1 of argv
      set launchCommand to item 2 of argv
      set openClicked to false
      repeat
        if openClicked then
          set dialogResult to display dialog dialogText buttons {"Done", "Open"} default button "Open" with title "Manual Step Required"
        else
          set dialogResult to display dialog dialogText buttons {"Done", "Open"} default button "Open" with title "Manual Step Required"
        end if
        set theButton to button returned of dialogResult
        if theButton is "Open" then
          do shell script launchCommand
          set openClicked to true
        else if theButton is "Done" and openClicked then
          exit repeat
        end if
      end repeat
    end run
  ' "$1" "$2"
}

# Kill running processes to apply changes
killall "System Settings" 2>/dev/null
killall "Finder"

# Reference: https://gist.github.com/rmcdongit/f66ff91e0dad78d4d6346a75ded4b751

# --- iCloud ---
popup "Change your profile picture to the previous iCloud one." "open "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane""
popup "Enable Touch ID for Media & Purchases." "open "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane?com.apple.AppleMediaServicesUI.SpyglassPurchases""

# --- Sound ---
popup "Set Alert Sound to Pluck." "open "x-apple.systempreferences:com.apple.Sound-Settings.extension""
# Play sound on startup = Off
popup "Insert password in your terminal after pressing Done." ""
sudo nvram StartupMute=%01

# --- Appearance ---
# Sidebar icon size = Medium
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# --- Control Center ---
# Bluetooth = Don’t Show in Menu Bar
defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool false
# Sound = Always Show in Menu Bar
defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true
# Battery = Off
defaults write com.apple.controlcenter "NSStatusItem Visible Battery" -bool false
# Spotlight = Don’t Show in Menu Bar
popup "Scroll down to Menu Bar Only, for Spotlight select Don't show in Menu bar." "open "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension?""

# --- Desktop & Dock ---
# Size = 20% small
defaults write com.apple.dock tilesize -int 36
# Position = Bottom
defaults write com.apple.dock orientation -string "bottom"
# Minimize using = Scale Effect
defaults write com.apple.dock mineffect -string "scale"
# Auto-hide dock
defaults write com.apple.dock autohide -bool true
# Animate opening apps = Off
defaults write com.apple.dock launchanim -bool false
# Show recent apps in Dock = Off
defaults write com.apple.dock show-recents -bool false
# Stage Manager settings require manual adjustment
popup "For Desktop & Stage Manager untick all Show Items." "open "x-apple.systempreferences:com.apple.Desktop-Settings.extension?Dock""
popup "Set 'Click wallpaper to reveal desktop' to 'Only in Stage Manager'." "open "x-apple.systempreferences:com.apple.Desktop-Settings.extension?Dock""
# Hot Corners = Off
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-br-corner -int 0
killall Dock

# --- Displays ---
popup "Set display scaling to 'More Space'." "open "x-apple.systempreferences:com.apple.Displays-Settings.extension""

# --- Touch ID & Password ---
popup "Enable Apple Watch unlock." "open "x-apple.systempreferences:com.apple.Touch-ID-Settings.extension?""

# --- Game Center ---
# popup "Open Game Center app and accept the login prompt." "open -a \"Game Center\""

# --- Keyboard ---
# Correct spelling automatically = Off
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
popup "Edit input sources." "open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension""

# --- Finder ---
# Show nothing on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
# New Finder windows show = Javin
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/Javin"
# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Disable extension change warning
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# View options
defaults write com.apple.finder ShowTabView -bool true
defaults write com.apple.finder ShowToolbar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# Reveal hidden files (toggle CMD+Shift+.)
defaults write com.apple.finder AppleShowAllFiles -bool true
# Sidebar items – manual setup
popup "Add sidebar items (Applications, Downloads, Javin, iCloud Drive, External disks)." \
"osascript -e \"tell application \\\"Finder\\\" to activate\" -e \"tell application \\\"System Events\\\" to tell process \\\"Finder\\\" to click menu item \\\"Settings…\\\" of menu \\\"Finder\\\" of menu bar 1\""

# Done
echo "✅ macOS configuration script complete. Some settings must still be done manually."
