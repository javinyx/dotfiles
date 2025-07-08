#!/bin/bash

# Source: https://patorjk.com/software/taag/#p=display&f=Ogre&t=Javinyx
logo="
   __              _
   \ \  __ ___   _(_)_ __  _   ___  __
    \ \/ _\` \ \ / / | '_ \| | | \ \/ /
 /\_/ / (_| |\ V /| | | | | |_| |>  <
 \___/ \__,_| \_/ |_|_| |_|\__, /_/\_\\
                           |___/
"
echo "$logo"

os_name=$(uname)
echo "Detected OS: $os_name"

if [[ "$os_name" == "Darwin" ]]; then
    echo "Running MacOS scripts..."
    source <(curl -s https://raw.githubusercontent.com/javinyx/dotfiles/main/install/macos/settings.sh)
    source <(curl -s https://raw.githubusercontent.com/javinyx/dotfiles/main/install/macos/packages.sh)
else
    echo "Unsupported OS. Only MacOS (Darwin) is supported for now."
    exit 1
fi