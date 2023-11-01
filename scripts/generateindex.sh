#!/bin/sh

# Initialize the index.html file and add HTML header
echo "<html>" > index.html
echo "<head><title>Package Information</title></head>" >> index.html
echo "<body>" >> index.html
echo "<table border='1'>" >> index.html
echo "<tr><th>Name</th><th>Version</th><th>Maintainer</th><th>Comment</th><th>Description</th></tr>" >> index.html

# Loop through each .pkg file in the directory
for pkg in *.pkg; do
  # Display a message about which package is currently being processed
  echo "Processing $pkg ..."

  # Extract the .MANIFEST file
  tar -xf "$pkg" "+MANIFEST"

  # Read the relevant fields from the .MANIFEST file, assuming it's in JSON format
  name=$(jq -r '.name' "+MANIFEST")
  version=$(jq -r '.version' "+MANIFEST")
  maintainer=$(jq -r '.maintainer' "+MANIFEST")
  comment=$(jq -r '.comment' "+MANIFEST")
  desc=$(jq -r '.desc' "+MANIFEST")

  # Add the data to the index.html file
  echo "<tr><td>$name</td><td>$version</td><td>$maintainer</td><td>$comment</td><td>$desc</td></tr>" >> index.html

  # Remove the extracted .MANIFEST file
  rm "+MANIFEST"
done

# Add HTML footer and close the table
echo "</table>" >> index.html
echo "</body>" >> index.html
echo "</html>" >> index.html

# Display a message indicating the script has finished
echo "Finished generating index.html"
