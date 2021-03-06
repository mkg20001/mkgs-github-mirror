#!/bin/bash

set -e

. config.sh

main=$(dirname $(readlink -f $0))

mkdir -p backup
cd backup
  for user in $users; do
    bash $main/github-backup/github-backup.sh $user stagit trash
  done
  for org in $orgs; do
    bash $main/github-backup/github-backup.sh $org org stagit trash
  done
  for u in $users $orgs; do
    config=$main/config.sh bash $main/host-zeronet.sh $u
  done
cd $main

echo "Update trees"
cd $zerodir
tree -h -H ./git git > tree.html
tree -h -J git > tree.json
sed 's|<title>Directory Tree</title>|<title>Git Directory Tree</title>\n  <link rel="stylesheet" type="text/css" href="style.css" />|' -i tree.html

echo "Sign & Publish"

cd $main/scripts && node remove-optional.js "$zerodir/content.json" && node sign.js "$zite"
