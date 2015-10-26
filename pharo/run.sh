#!/bin/bash

set -e

# Helper functions
# ==============================================================================
function print_info {
    printf "\e[0;34m$1\e[0m\n"
}

function print_notice {
    printf "\e[1;33m$1\e[0m\n"
}

function print_success {
    printf "\e[1;32m$1\e[0m\n"
}

function print_error {
    printf "\e[1;31m$1\e[0m\n"
}
# ==============================================================================

# Set paths and files
# ==============================================================================
[ -z "$FILETREE_CI_BUILD_BASE" ] && FILETREE_CI_BUILD_BASE="$FILETREE_CI_HOME/_builds"
[ -z "$PACKAGES" ] && PACKAGES="/packages"
# ==============================================================================

# Determine Pharo download url
# ==============================================================================
case "$SMALLTALK" in
    "Pharo-4.0")
        PHARO_GET_URL="get.pharo.org/40+vm"
        ;;
    "Pharo-5.0")
        PHARO_GET_URL="get.pharo.org/50+vm"
        ;;
    *)
        print_error "Unsupported Pharo version ${SMALLTALK}"
        exit 1
        ;;
esac
# ==============================================================================

# Prepare folders
# ==============================================================================
print_info "Preparing folders..."
[[ -d "$FILETREE_CI_BUILD_BASE" ]] || mkdir "$FILETREE_CI_BUILD_BASE"
pushd $FILETREE_CI_BUILD_BASE > /dev/null
# ==============================================================================

# Prepare image and virtual machine
# ==============================================================================
print_info "Downloading Pharo image and vm..."
wget --quiet -O - ${PHARO_GET_URL} | bash
# ==============================================================================

# Load project and run tests
# ==============================================================================
print_info "Loading project..."
./pharo Pharo.image eval --save "
Metacello new 
    baseline: '${BASELINE}';
    repository: 'filetree://${PROJECT_HOME}/${PACKAGES}';
    load.
"

print_info "Run tests..."
EXIT_STATUS=0
./pharo Pharo.image test --fail-on-failure "${BASELINE}.*" 2>&1 || EXIT_STATUS=$?
# ==============================================================================
popd > /dev/null

exit $EXIT_STATUS