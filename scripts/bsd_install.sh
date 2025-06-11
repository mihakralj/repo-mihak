#!/bin/sh

# Initialize variables to keep track of processed packages and URLs
processed_deps=""
processed_urls=""
pkg_add_commands=""

# Function to fetch and prepare the FreeBSD package catalog
get_freebsd_catalog() {
  # Extract the FreeBSD version and construct the repository URL
  freebsd_version=$(freebsd-version -u | cut -d- -f1 | cut -d. -f1)
  repourl="https://pkg.freebsd.org/FreeBSD:${freebsd_version}:$(uname -m)/latest"

  # Create a temporary directory for storing package data
  tmp_dir="/tmp/pkg_site_tmp_dir" && mkdir -p "$tmp_dir"

  # Fetch and unpack the packagesite file
  fetch -q -o "${tmp_dir}/packagesite.pkg" "${repourl}/packagesite.pkg"
  tar -xf "${tmp_dir}/packagesite.pkg" -C "$tmp_dir" packagesite.yaml
  rm "${tmp_dir}/packagesite.pkg" # Clean up the downloaded tar file
}

# Function to process a package and its dependencies
grep_package_in_catalog() {
  package_name="$1"

  # Skip processing if the package has already been handled
  echo "$processed_deps" | grep -qE "(^| )$package_name( |$)" && return 0

  # Add the package to the list of processed packages
  processed_deps="$processed_deps $package_name"

  # Check if the package is already in the repository
  pkg search "$package_name" | grep -qE "^$package_name-" && return 0

  # Retrieve package information from the local catalog
  package_info=$(grep "\"name\":\"$package_name\"" "${tmp_dir}/packagesite.yaml")
  [ -z "$package_info" ] && echo "Package $package_name not found" && return 1

  # Extract and process dependencies
  dependencies=$(echo "$package_info" | jq -r '.deps | keys[]' 2>/dev/null)
  for dep in $dependencies; do
    grep_package_in_catalog "$dep"
  done

  # Construct the package URL
  package_url="${repourl}/$(echo "$package_info" | jq -r '.repopath')"

  # Skip if the package URL has already been processed
  echo " $processed_urls " | grep -q " $package_url " && return 0

  # Add the package URL to the list of processed URLs and commands
  processed_urls="$processed_urls $package_url"
  echo "pkg add $package_url"
  pkg_add_commands="$pkg_add_commands\npkg add $package_url"
}

# The main() part of the script starts here

# Check for required package name argument
[ $# -eq 0 ] && { echo "Usage: $0 <package_name>"; exit 1; }

# Ensure jq is installed for JSON processing
command -v jq >/dev/null 2>&1 || pkg install -yq jq

# Fetch the FreeBSD package catalog
get_freebsd_catalog

# Fetch and display the package information
package_info=$(grep "\"name\":\"$1\"" "${tmp_dir}/packagesite.yaml")
[ -z "$1" ] && echo "Package $1 not found" && return 1
echo $package_info | jq -r '"\u001b[33m\(.name)\u001b[0m:\n\(.desc)"'
printf "\033[32mto install $1:\033[0m\n"

# Process the specified package and its dependencies
grep_package_in_catalog "$1"

# Ask for confirmation and execute the commands
printf "Do you want to execute this? (y/n) "
read answer
[ "$answer" = "y" ] && printf "%b" "$pkg_add_commands" | sh
