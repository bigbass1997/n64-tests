#!/bin/bash

ROM_NAME="SI-Test.z64"

action="$1"

if [ "$action" == "build" ]; then
    ../bass src/main.asm -strict -benchmark
    ../chksum64 "$ROM_NAME"
fi


if [ "$action" == "run" ]; then
    ../bass src/main.asm -strict -benchmark
    ../chksum64 "$ROM_NAME"
    
    mame n64 -window -switchres -resolution 1280x960 -nofilter -cart "$ROM_NAME"
fi


if [ "$action" == "debug" ]; then
    ../bass src/main.asm -strict -benchmark
    ../chksum64 "$ROM_NAME"
    
    mame n64 -debug -log -verbose -window -switchres -resolution 1280x960 -nofilter -cart "$ROM_NAME"
fi
