#!/bin/bash
#Patrick Collins (Patricol)

cd "${0%/*}"

find ./apps/ -maxdepth 1 -mindepth 1 -type d -exec cp ./analyze.sh {} \;
find ./apps/ -maxdepth 1 -mindepth 1 -type d -print0 | xargs -0 -n 1 -P 4 -I '{}' /bin/bash '{}'/analyze.sh
find ./apps/ -maxdepth 1 -mindepth 1 -type d -exec rm {}/analyze.sh \;
find ./apps/ -maxdepth 1 -mindepth 1 -type d -exec mv {}/out.txt {}-output.txt \;
