#!/bin/bash
#Patrick Collins (Patricol)

cd "${0%/*}"
cd "./apps/"

find ./ -maxdepth 1 -mindepth 1 -type f -name "*.apk" -exec apktool d {} \;