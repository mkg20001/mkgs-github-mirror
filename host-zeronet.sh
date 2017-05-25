#!/bin/bash

. $config

if [ -z "$1" ]; then
  echo "Usage: $0 <username>"
  exit 2
fi

check_blacklist() {
  for b in $blacklist; do
    if [ "$b" == "$1" ]; then
      return 1
    fi
  done
  return 0
}

log() {
  echo " => $@"
}
log2() {
  q=${@/"$1"/""}
  echo "    => [$1] $q"
}
log3() {
  echo "    => $@"
}

exit_code() {
  if [ $1 -ne 0 ]; then
    echo "ERROR: $2!"
    exit $1
  fi
}

find_in_json() {
  line=$(echo "$prejson" | grep "^\\[$2\\]")
  if [ -z "$line" ]; then
    echo "WARN: Nothing found for $2" 1>&2
  else
    IFS="$tab" read -ra find <<< "$line"
    echo "${find[1]}"
  fi
}

no_quote() {
  read _in
  temp="${_in%\"}"
  temp="${temp#\"}"
  echo "$temp"
}

main=$(dirname $(readlink -f $0))
stamain="$main/github-backup/stagit"
stagit="$stamain/stagit"
scripts="$main/scripts"

usage() {
  echo
  echo "Usage: $0 <username> [stagit] [org]"
  echo
  echo " domain=<domain> - Domain used for hosting"
#  echo " org           - <username> is a GitHub organization"
#  echo " extended      - Allow extended api calls to get information about forks (you run out of quota soon) (will be saved in USER/repos/REPO.json)"
#  echo " token=<token> - Use an Authorization Token"
#  echo " -h            - This help text."
  echo
}

parse_options() {
  set -- "$@"
  local ARGN=$#
  while [ "$ARGN" -ne 0 ]
  do
    if [ -z "$user" ]; then
      user="$1"
    else
      case $1 in
        -h) usage
            exit 0
        ;;
        stagit) isstagit=true
        ;;
        all) :
        ;;
        org) isorg=true
        ;;
        extended) allowextendedinfo=true
        ;;
        token=*) token=${1/"token="/""};hastoken=true
        ;;
        ?*) echo "ERROR: Unknown option."
            usage
            exit 1
        ;;
      esac
    fi
    shift 1
    ARGN=$((ARGN-1))
  done
  if [ -z "$user" ]; then
    usage
    exit 1
  fi
}

domain="example.com"

parse_options "$@"

log "ZeroNet Rehost v1"

userb="$PWD/$1"
userR="$userb/repos"
userS="$userb/stagit"
userC="$userb/stagit.cache"
out="$userb-rehost"
mkdir -p $out

if ! [ -e "$userb" ]; then
  echo "$userb not found"
  echo "Run $ github-backup.sh $user stagit"
  exit 2
fi
if ! [ -e "$userS" ]; then
  echo "$users not found"
  echo "Run $ github-backup.sh $user stagit"
  exit 2
fi

if [ "$2" == "all" ]; then
  log "Update assets (devmode)"
  for r in style.css favicon.png logo.png; do
    cp $main/assets/$r $zerodir/git/$user/$r
  done
  for repo in $(dir -w 1 $userR); do
    echo "r $repo"
    cp $main/assets/$r $zerodir/git/$user/$repo/$r
  done
  exit 0
fi

rm -rf $out
mkdir -p $out

mkdir -p $zerodir/git/$user

log "Copy resources"
cp $main/assets/style.css $out/style.css

cp $stamain/logo.png $out/avatar.png
cp $out/avatar.png $out/favicon.png
cp $out/avatar.png $out/logo.png


log "Copy files into destination"

cd $out

dw=false

wait_pids() {
  running=0
  ok=true
  npids=""
  for PID in $pids; do
    if [ -e /proc/$PID ]; then
      let running=$running+1
      npids="$npids $PID"
    fi
  done
  pids="$npids"
  if [ $running -gt $1 ]; then
    dw=true
    echo -n .
    sleep .1s
    wait_pids $1
  else
    [ $running -gt 5 ] && sleep .05s
    if $dw; then echo;dw=false; fi
  fi
}

repos=$(dir -w 1 $userR)
repos_g=""
for repo in $repos; do
  if check_blacklist "$user/$repo"; then
    log "Copy $repo"
    if ! [ -e "$userS/$repo" ]; then
      echo "WARN: stagit folder for $repo not found"
    fi
    log3 "Copying bare repo"
    cp -rp $userR/$repo $out/$repo.git
    log3 "Copying HTML"
    cp -rp $userS/$repo $out/$repo
    log3 "Copying stagit cache"
    cp -rp $userC/$repo $out/$repo.cache

    newurl="http://localhost:43110/$zitename/git/$user/$repo.git.tar.gz/$repo.git"
    log3 "Update url to $newurl"
    echo "$newurl" > $out/$repo.git/url
    cd $out/$repo

    log3 "Update server info"

    cd $out/$repo.git
    git update-server-info

    cd $out/$repo

    log3 "Run stagit to apply changes"
    $stagit -c $out/$repo.cache $out/$repo.git
    exit_code $? "stagit failed"

    rm $out/$repo.cache

    log3 "HTMLMIN"
    cd $out/$repo
    pids=""
    pre=$(du -s .)
    find -iname "*.html" > $scripts/files
    cd $scripts;node $scripts/minifyall.js $out/$repo;cd $out/$repo
    wait_pids 0
    find -iname "*.html.orig" -delete
    after=$(du -s .)
    echo "Minify: $pre => $after"
    echo "Minify: $pre => $after" > $out/$repo.minify
    repos_g="$repos_g $repo.git"
    cd $out
  else
    log "Ignore blacklisted repo $user/$repo"
  fi
done

cd $out

log "Update index"

${stagit}-index $repos_g > index.html
exit_code $? "stagit-index failed"

cd $out

rm -rfv "$zerodir/git/$user"
mkdir "$zerodir/git/$user"

for repo in $repos; do
  if check_blacklist "$user/$repo"; then
    log "ZeroHost $repo"
    repopath="$zerodir/git/$user/$repo"
    log3 "Update HTML"
    rm -rf $repopath $repopath.tar.gz
    find $repo -print0 | xargs -0i touch -a -m -t 200001010000.00 {}
    tar cfz $repopath.tar.gz $repo
    rm -rf $out/$repo
    log3 "Update git"
    rm -rf $repopath.git $repopath.git.tar.gz
    find $repo.git -print0 | xargs -0i touch -a -m -t 200001010000.00 {}
    tar cfz $repopath.git.tar.gz $repo.git
    rm -rf $out/$repo.git
  else
    log "Ignore blacklisted repo $user/$repo"
  fi
done

log "Replace index.html"
rm -f $zerodir/git/$user/index.html
node $scripts/index-fix.js $out/index.html
mv $out/index.html $zerodir/git/$user/index.html

log "Update assets"
for r in style.css favicon.png logo.png; do
  cp $out/$r $zerodir/git/$user/$r
  rm $out/$r
done

log "Sign & Publish your content.json"
