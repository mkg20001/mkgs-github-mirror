# mkgs-github-mirror

The sourcecode behind the zeronet zite [git.mkg20001.bit](http://localhost:43110/git.mkg20001.bit)

# Installing

## Ubuntu/Debian

Install nodeJS: `curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -`

Install libs: `sudo apt install -y libgit2-dev libc6-dev`

Compile stagit: `make -C github-backup/stagit`

npm i: `npm i && cd github-backup && npm i`

# Config

See [config.sh example](/config.sh.example)

# Mirror

To mirror just run "update-mirror.sh" after setting up your config
