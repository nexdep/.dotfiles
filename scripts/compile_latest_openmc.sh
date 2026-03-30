#!/usr/bin/env bash

# these tools are supposed to be installed after the github setup ubuntu script
sudo apt install g++ cmake libhdf5-dev libpng-dev

SCRIPT_USER="marco"
SCRIPT_HOME="/home/$SCRIPT_USER"
SCRIPT_REPOS="$SCRIPT_HOME/repos"

mkdir -p "$SCRIPT_REPOS"
cd "$SCRIPT_REPOS"

# clone
git clone \
  --branch develop \
  --single-branch \
  --depth 1 \
  --recurse-submodules \
  https://github.com/openmc-dev/openmc.git

# compile
cd openmc
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local ..
make
sudo make install

# install python modules
cd "$SCRIPT_REPOS/openmc"
python -m pip install -e '.[test]'
python -m pip install openmc-plotter
