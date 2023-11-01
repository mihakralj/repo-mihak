#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage: $0 <package-name>"
  exit 1
fi

###############################

get_package_url() {
  local package_name="$1"
  local indent="$2"

  # Find the line with the requested package
  local line=$(awk -v package="$package_name" '$0 ~ "{\"name\":\"" package "\"" {print $0}' "${tmp_dir}/packagesite.yaml")

  # Check if the line is empty
  if [ -z "$line" ]; then
    echo "${indent}Error: Package $package_name not found."
    return
  fi

  # Get URL
  local repopath="https://pkg.freebsd.org/FreeBSD:${freebsd_version}:${freebsd_abi}/latest/$(echo "$line" | grep -o '"repopath":"[^"]*"' | cut -d\" -f4)"
  echo "${indent}sudo pkg add $repopath"

  # Extract dependencies
  local dep_content=$(echo "$line" | awk -F'"deps":{' '{print $2}' | awk -F'},"categories"' '{print $1}')
  local deps=$(echo "$dep_content" | grep -o '"[^"]*":{"origin"' | sed 's/":{"origin"//g' | tr -d '"')

  # Recursive call for each dependency with increased indentation
  for dep in $deps; do
    get_package_url "$dep" "${indent}  "
  done
}

###############################

# Package name
package_name="$1"

# Determine FreeBSD version and ABI
freebsd_version=$(freebsd-version -u | cut -d- -f1 | cut -d. -f1) # Taking the major version only
freebsd_abi=$(uname -m)

# URL to the packagesite file
url="https://pkg.freebsd.org/FreeBSD:${freebsd_version}:${freebsd_abi}/latest/packagesite.txz"

# Create a temporary directory if it doesn't exist
tmp_dir="/tmp/pkg_site_tmp_dir"
mkdir -p "$tmp_dir"

# Fetch and unpack the packagesite file if packagesite.yaml doesn't exist
if [ ! -f "${tmp_dir}/packagesite.yaml" ]; then
  fetch -o "${tmp_dir}/packagesite.txz" "$url"
  tar xf "${tmp_dir}/packagesite.txz" -C "$tmp_dir"
  rm "${tmp_dir}/packagesite.txz" # Delete the tar file after extracting
fi

# Call the function with initial indentation
get_package_url "$package_name" ""
