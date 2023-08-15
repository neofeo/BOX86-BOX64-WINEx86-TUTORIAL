#!/bin/bash

repo="Kron4ek/Wine-Builds"
api_url="https://api.github.com/repos/${repo}/releases"

# Fetch release information using the GitHub API
release_info=$(curl -s "${api_url}")

# Loop through each release and extract package names
for release in $(echo "$release_info" | jq -r '.[] | @base64'); do
    _jq() {
      echo ${release} | base64 --decode | jq -r ${1}
    }

    release_version=$(_jq '.tag_name')
    package_names=$(_jq '.assets[]?.name')

    echo "Release Version: ${release_version}"
    echo "Package Names: ${package_names}"
    echo
done
