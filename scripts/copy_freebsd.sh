#!/bin/sh

FILE="freebsd.list"
tmp_dir="/path/to/tmp_dir"  # Replace with actual temporary directory path

get_package_url() {
  local package_name="$1"

  local line=$(awk -v package="$package_name" '$0 ~ "{\"name\":\"" package "\"" {print $0}' "${tmp_dir}/packagesite.yaml")

  if [ -z "$line" ]; then
    echo "Error: Package $package_name not found."
    return
  fi

  # Check if the exact package is NOT available in current repos
  if ! pkg search -x "^${package_name}-[0-9]+.*$" > /dev/null 2>&1; then
    # Construct the repo URL based on your pattern
    local repo_url="https://pkg.freebsd.org/FreeBSD:${freebsd_version}:${freebsd_abi}/latest/"
    echo "Debug: Repo URL: $repo_url"  # Debug print

    local repopath="${repo_url}$(echo "$line" | grep -o '"repopath":"[^"]*"' | cut -d\" -f4)"
    echo "Debug: Repo Path: $repopath"  # Debug print

    wget -P /repo/freebsd $repopath
  else
    echo "${package_name} is available"
  fi

  local dep_content=$(echo "$line" | awk -F'"deps":{' '{print $2}' | awk -F'},"categories"' '{print $1}')
  local deps=$(echo "$dep_content" | grep -o '"[^"]*":{"origin"' | sed 's/":{"origin"//g' | tr -d '"')

  for dep in $deps; do
    get_package_url "$dep"
  done
}



prepare_package_site() {
  # Determine FreeBSD version and ABI
  freebsd_version=$(freebsd-version -u | cut -d- -f1 | cut -d. -f1)
  freebsd_abi=$(uname -m)

  # URL to the packagesite file
  url="https://pkg.freebsd.org/FreeBSD:${freebsd_version}:${freebsd_abi}/latest/packagesite.txz"

  # Create a temporary directory if it doesn't exist
  tmp_dir="/tmp/pkg_site_tmp_dir"
  mkdir -p "$tmp_dir"

  # Fetch and unpack the packagesite file if packagesite.yaml doesn't exist
  if [ -f "${tmp_dir}/packagesite.yaml" ]; then
    rm "${tmp_dir}/packagesite.yaml"
  fi
  fetch -o "${tmp_dir}/packagesite.txz" "$url"
  tar xf "${tmp_dir}/packagesite.txz" -C "$tmp_dir"
  rm "${tmp_dir}/packagesite.txz"
}

################ start of the script

prepare_package_site

# Check if the file exists
if [ -f "$FILE" ]; then
  while IFS= read -r package; do
    get_package_url "$package"
  done < "$FILE"
fi