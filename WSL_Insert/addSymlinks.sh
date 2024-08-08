#!/bin/bash

# target dir for the symlinks
TARGET_DIR="/usr/local/bin"

# path to nodejs script handling e.g. cmd.exe cmds, no problem bc its a node build by default --> see dockerfile
NODE_SCRIPT="/WSL/script.js"

# symlink for cmd.exe and powershell.exe
ln -sf "$NODE_SCRIPT" "$TARGET_DIR/cmd.exe"
ln -sf "$NODE_SCRIPT" "$TARGET_DIR/powershell.exe"

echo "Symlinks got created in $TARGET_DIR:"
ls -l "$TARGET_DIR/cmd.exe" "$TARGET_DIR/powershell.exe"