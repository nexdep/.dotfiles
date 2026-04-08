#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# OpenMC Development Environment Setup Script
# -----------------------------------------------------------------------------
# This script:
# 1. Creates a fresh conda environment with required dependencies
# 2. Clones the OpenMC repository (develop branch)
# 3. Builds and installs OpenMC from source into the conda environment
# 4. Installs Python bindings + testing extras
# 5. Verifies the installation
#
# -----------------------------------------------------------------------------
# USAGE:
#
#   copy the script in the folder where to download openmc
#   ./build_conda_openmc_latest.sh
#
# REQUIREMENTS:
#   - Conda (Miniconda or Anaconda) installed and initialized
#   - Internet connection
#   - Linux/macOS (uses nproc)
#
# OPTIONAL:
#   - Modify ENV_NAME or PY_VER below if needed
#
# NOTES:
#   - Existing environments with the same name will cause failure
#   - Build uses all available CPU cores
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, and failed pipes

# ---------------------------
# Configuration
# ---------------------------
ENV_NAME="openmc-dev-latest"  # Name of the conda environment
PY_VER="3.14"                 # Python version

# ---------------------------
# Create conda environment
# ---------------------------
echo "Creating conda environment: $ENV_NAME"

conda create -y -n "$ENV_NAME" \
  python="$PY_VER" \
  cmake make git compilers hdf5 pip numba \
  -c conda-forge

# ---------------------------
# Activate environment
# ---------------------------
# Ensure conda activation works in scripts
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

echo "Activated environment: $ENV_NAME"

# ---------------------------
# Clone OpenMC repository
# ---------------------------
echo "Cloning OpenMC (develop branch)"

git clone --recurse-submodules \
  --branch develop \
  https://github.com/openmc-dev/openmc.git

cd openmc

# Ensure correct branch and submodules
git checkout develop
git submodule update --init --recursive

# ---------------------------
# Build OpenMC
# ---------------------------
echo "Building OpenMC"

mkdir -p build
cd build

# Configure build with install prefix = current conda env
cmake -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" ..

# Compile using all available CPU cores
make -j"$(nproc)"

# Install into conda environment
make install

# ---------------------------
# Install Python bindings
# ---------------------------
cd ..

echo "Installing Python package (editable mode with tests)"

pip install -e '.[test]'

# Optional plotting tool
pip install openmc-plotter

# ---------------------------
# Verification
# ---------------------------
echo "Verifying installation"

python - <<EOF
import openmc, numba
print("openmc:", openmc.__version__)
print("numba:", numba.__version__)
EOF

# Check CLI availability
echo "OpenMC executable location:"
which openmc

echo "Setup complete!"
