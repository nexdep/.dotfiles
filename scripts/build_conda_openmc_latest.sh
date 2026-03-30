#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="openmc-dev-latest"
PY_VER="3.14"

conda create -y -n "$ENV_NAME" python="$PY_VER" cmake make git compilers hdf5 pip numba -c conda-forge

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

git clone --recurse-submodules --branch develop https://github.com/openmc-dev/openmc.git
cd openmc
git checkout develop
git submodule update --init --recursive

mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" ..
make -j"$(nproc)"
make install

cd ..
pip install -e '.[test]'
pip install openmc-plotter

python -c "import openmc, numba; print('openmc:', openmc.__version__); print('numba:', numba.__version__)"
which openmc
