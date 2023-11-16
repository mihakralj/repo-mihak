#!/bin/sh

# Create /repo/plugins directory
mkdir -p /repo/plugins

# Loop through each directory in /repo-mihak/plugins
for dir in /repo-mihak/plugins/*; do
  if [ -d "$dir" ]; then
    # Switch to the directory
    cd "$dir" || continue

    # Run 'make package'
    make package

    # Check if a new package was created in ./work/pkg
    if [ -d "./work/pkg" ]; then
      # Copy the package into /repo/plugins
      cp -r ./work/pkg/* /repo/plugins/
    fi
  fi
done