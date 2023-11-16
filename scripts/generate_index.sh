#!/bin/sh

packagesite="/repo/packagesite.txz"
tmp_dir="/tmp"

tar -xf $packagesite -C $tmp_dir packagesite.yaml

cat ../README.md > index.md
# Loop through each line in the JSON file
while IFS= read -r line
do
    # Use jq to format each JSON line to a Markdown-friendly format
    echo "$line" | jq -r '
        "#### \(.name): \(.comment)\n",
        "**Maintainer:** \(.maintainer)\n",
        "**Website:** [\(.www)](\(.www))\n",
        "**File:** \(.repopath)\n",
        "**Dependencies:** " + (if .deps then [(.deps[] | .origin | split("/")[1])] | join(", ") else "N>
        "\(.desc)\n",
        "---\n"'
done < $tmp_dir/packagesite.yaml >> $tmp_dir/index.md
pandoc $tmp_dir/index.md -s -css markdown.css --metadata title="OPNsense community repository" -o /repo/index.html