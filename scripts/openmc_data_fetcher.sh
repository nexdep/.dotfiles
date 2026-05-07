#!/usr/bin/env bash
set -euo pipefail

# Base directories
OPENMC_BASE_DIR="${HOME}/openmc_data"
CHAIN_TYPE="chain_endfb81_fast"
CHAIN_DIR="${OPENMC_BASE_DIR}/${CHAIN_TYPE}"

mkdir -p "${OPENMC_BASE_DIR}"
mkdir -p "${CHAIN_DIR}"

cd "${OPENMC_BASE_DIR}"

# Download and extract cross section data (skip if cross sections are already there)
if [ ! -e "${OPENMC_BASE_DIR}/endfb-viii.0-hdf5/cross_sections.xml" ]; then
  curl -L "https://anl.box.com/shared/static/uhbxlrx7hvxqw27psymfbhi7bx7s6u6a.xz" \
    | tar -xJf -
fi

# Define OPENMC_CROSS_SECTIONS variable using $HOME
OPENMC_CROSS_SECTIONS="$(realpath "${OPENMC_BASE_DIR}/endfb-viii.0-hdf5/cross_sections.xml")"

# Download chain file (always refresh; change if you want caching)
curl -L -o "${CHAIN_DIR}/${CHAIN_TYPE}.xml" \
	"https://anl.box.com/shared/static/n0pkqe66uotskoljr93szvjyvtvycgze.xml" 

OPENMC_CHAIN_FILE="$(realpath "${CHAIN_DIR}/${CHAIN_TYPE}.xml")"

# Append exports to ~/.zshrc only if not already defined there
ZSHRC="${HOME}/.zshrc"
touch "${ZSHRC}"

if ! grep -q 'OPENMC_CROSS_SECTIONS' "${ZSHRC}"; then
  {
    echo ""
    echo "# OpenMC data configuration"
    echo "export OPENMC_CROSS_SECTIONS=\"${OPENMC_CROSS_SECTIONS}\""
  } >> "${ZSHRC}"
fi

if ! grep -q 'OPENMC_CHAIN_FILE' "${ZSHRC}"; then
  echo "export OPENMC_CHAIN_FILE=\"${OPENMC_CHAIN_FILE}\"" >> "${ZSHRC}"
fi

echo "OPENMC_CROSS_SECTIONS=${OPENMC_CROSS_SECTIONS}"
echo "OPENMC_CHAIN_FILE=${OPENMC_CHAIN_FILE}"
echo "Done. Restart your shell or run: source ~/.zshrc"
