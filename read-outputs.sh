#!/bin/bash
#Patrick Collins (Patricol)

cd "${0%/*}"
find ./apps/ -maxdepth 1 -type f -name "*-output.txt" -exec cat {} \;
find ./apps/ -maxdepth 2 -mindepth 2 -type f -name "out.txt" -exec cat {} \;
