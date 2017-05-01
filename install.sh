#!/bin/bash

set -ex

[ ! -e config.sh ] && cp config.sh.example config.sh

git submodule init
git submodule update
npm i

cd github-backup
git submodule init
git submodule update
npm i
