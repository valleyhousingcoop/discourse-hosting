#!/bin/bash
# Install all the discourse plugins from the plugins.txt file
set -euxo pipefail

cd plugins
grep -v '^#' ../plugins.txt  | while read -r plugin; do
    git clone "https://github.com/$plugin.git"
done
