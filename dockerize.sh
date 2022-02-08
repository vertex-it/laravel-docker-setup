#!/bin/bash

export REPO_URL="git@github.com:vertex-it/laravel-docker-setup.git"

echo "Starting to dockerize..."

git clone --depth=1 -q $REPO_URL dockerize

rm ./dockerize/.git ./dockerize/README.md ./dockerize/dockerize.sh

shopt -s dotglob nullglob
mv ./dockerize/* .

rm -rf ./dockerize

echo 'Done. Enter the command "./ver" to run the CLI.'
