#!/usr/bin/env sh


TARGET_PATH="$(pwd)/deployed/sh"
NEW_LINE="export PATH=\$PATH:$TARGET_PATH"
echo $NEW_LINE
touch ~/.bashrc
grep -qxF "$NEW_LINE" ~/.bashrc || echo "$NEW_LINE" >> ~/.bashrc

./deploy.sh

echo "reboot your terminal to access the commands"