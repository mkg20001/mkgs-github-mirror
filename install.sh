#!/bin/bash

set -ex

git submodule init
git submodule update
npm i
cd github-backup && npm i
