#!/bin/bash

# --- GENERIC DEPLOYMENT SCRIPT (BASH) ---
echo "--- Starting Deployment Script... ---"

# --- Configuration ---
# Find the script's own directory to make it portable
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CONFIG_FILE="$SCRIPT_DIR/config.json"

# Function to read a value from the JSON config file
get_config_value() {
    grep -o "\"$1\": \"[^\"]*\"" "$CONFIG_FILE" | cut -d'"' -f4
}

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found at '$CONFIG_FILE'." >&2
    echo "Please copy 'config.example.json' to 'config.json' in the 'deploy' folder and fill in your details." >&2
    exit 1
fi

PI_USER=$(get_config_value "piUser")
PI_IP_ADDRESS=$(get_config_value "piIpAddress")
TEMP_DIR_ON_PI=$(get_config_value "tempDirOnPi")
FINAL_DIR_ON_PI=$(get_config_value "finalDirOnPi")

# Optional config with defaults
BUILD_COMMAND=$(get_config_value "buildCommand")
BUILD_DIR=$(get_config_value "buildDir")
BUILD_COMMAND=${BUILD_COMMAND:-"npm run build"}
BUILD_DIR=${BUILD_DIR:-"build"}

# Check if required config values are set
if [ -z "$PI_USER" ] || [ -z "$PI_IP_ADDRESS" ] || [ -z "$TEMP_DIR_ON_PI" ] || [ -z "$FINAL_DIR_ON_PI" ]; then
    echo "One or more configuration values are missing in '$CONFIG_FILE'." >&2
    exit 1
fi

# Get project root (parent of deploy folder)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
SOURCE_DIR="$PROJECT_ROOT/$BUILD_DIR"
TAR_FILE="build.tar.gz"

# --- Script ---
# Change to project root directory
cd "$PROJECT_ROOT" || exit 1

# Step 1: Build the application for production
echo ""
echo "Step 1: Building the application..."
$BUILD_COMMAND
if [ $? -ne 0 ]; then
    echo "Build failed! Aborting deployment." >&2
    exit 1
fi

# Step 2: Compress build files
echo ""
echo "Step 2: Compressing build files..."
tar -czf "$TAR_FILE" -C "$SOURCE_DIR" .
if [ $? -ne 0 ]; then
    echo "Compression failed! Aborting deployment." >&2
    exit 1
fi

# Step 3: Transfer compressed archive to the remote server
echo ""
echo "Step 3: Transferring compressed archive to remote server..."
scp "$TAR_FILE" "${PI_USER}@${PI_IP_ADDRESS}:~/${TAR_FILE}"
if [ $? -ne 0 ]; then
    echo "SCP transfer failed! Aborting deployment." >&2
    rm -f "$TAR_FILE"
    exit 1
fi

# Step 4: Deploy files on the remote server via SSH
echo ""
echo "Step 4: Deploying files on the remote server..."
SSH_COMMAND="
mkdir -p $TEMP_DIR_ON_PI && \
tar -xzf ~/$TAR_FILE -C $TEMP_DIR_ON_PI && \
sudo rm -rf $FINAL_DIR_ON_PI/* && \
sudo mv $TEMP_DIR_ON_PI/* $FINAL_DIR_ON_PI/ && \
sudo chown -R www-data:www-data $FINAL_DIR_ON_PI && \
sudo chmod -R 755 $FINAL_DIR_ON_PI && \
rm -rf $TEMP_DIR_ON_PI ~/$TAR_FILE
"
ssh "${PI_USER}@${PI_IP_ADDRESS}" "$SSH_COMMAND"
if [ $? -ne 0 ]; then
    echo "SSH deployment commands failed! Please check permissions on the remote server." >&2
    rm -f "$TAR_FILE"
    exit 1
fi

# Step 5: Cleanup local tar file
rm -f "$TAR_FILE"

# Step 6: Completion
echo ""
echo "--------------------------------------------"
echo " Deployment complete! "
echo "--------------------------------------------"
echo ""
