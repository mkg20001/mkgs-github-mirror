. config.sh

cd backup

pre=$(du -hs .)

for u in $orgs $users; do
  echo " - Remove cache for $u"
  rm -rf $u-cache $u-rehost
  for repo in $(dir -w 1 $u/repos); do
    echo " -- Remove cache for repo $repo@$u"
    rm -rf $u/stagit/$repo $u/stagit.cache/$repo $u/stagit.cache/$repo.ver
  done
  rm -rf $u/stagit $u/stagit.cache
done

after=$(du -hs .)

echo "Space: $pre => $after"
