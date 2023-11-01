#!/bin/csh

# Check for Python 3.9
python3 --version
if ($status != 0) then
    pkg install -y python39
    if ($status != 0) then
        echo "Failed to install Python 3. Exiting."
        exit 1
    endif
endif

pip --version
if ($status != 0) then
    pkg install -y py39-pip
    if ($status != 0) then
        echo "Failed to install Python 3. Exiting."
        exit 1
    endif
endif

# Update PATH in .cshrc
echo 'setenv PATH "${PATH}:$HOME/.local/bin"' >> ~/.cshrc

# Install Azure CLI
python3 -m pip install --user azure-cli

# Reload .cshrc
source ~/.cshrc

# Check if Azure CLI is working
az --version
if ($status == 0) then
    echo "Azure CLI installed successfully."
else
    echo "Failed to install Azure CLI."
endif
