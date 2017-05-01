#!/bin/bash

. config.sh

main=$(dirname $(readlink -f $0))

mkdir -p backup
cd backup
  for user in $users; do
    bash $main/github-backup/github-backup.sh $user stagit trash
    config=$main/config.sh bash $main/host-zeronet.sh $user
  done
  for org in $orgs; do
    bash $main/github-backup/github-backup.sh $org org stagit trash
    config=$main/config.sh bash $main/host-zeronet.sh $org
  done
cd $main

echo "Update trees"
cd $zerodir
tree -h -H ./git git > tree.html
tree -h -J git > tree.json
sed 's|<title>Directory Tree</title>|<title>Git Directory Tree</title>\n  <link rel="stylesheet" type="text/css" href="style.css" />|' -i tree.html

echo \$ cd $HOME/ZeroNet
echo \$ python2 zeronet.py siteSign $zite
echo \$ python2 zeronet.py --fileserver_port 15555 sitePublish $zite
