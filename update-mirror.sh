#!/bin/bash

main=$(dirname $(readlink -f $0))

mkdir -p backup
cd backup
  for user in mkg20001 hellozeronet; do
    bash $main/github-backup/github-backup.sh $user stagit trash
    bash $main/host-zeronet.sh $user
  done
  for org in zeronerds lbryio yunit-io os-loader ipfs thetorproject; do
    bash $main/github-backup/github-backup.sh $org org stagit trash
    bash $main/host-zeronet.sh $org
  done
cd $main
zite="1F7b27kT38nMYZQg7tvDr33qWDZQgwnQpw"

echo "Update trees"
cd $HOME/ZeroNet/data/$zite
tree -h -H ./git git > tree.html
tree -h -J git > tree.json
sed 's|<title>Directory Tree</title>|<title>Git Directory Tree</title>\n  <link rel="stylesheet" type="text/css" href="style.css" />|' -i tree.html

echo \$ cd $HOME/ZeroNet
echo \$ python2 zeronet.py siteSign $zite
echo \$ python2 zeronet.py --fileserver_port 15555 sitePublish $zite
