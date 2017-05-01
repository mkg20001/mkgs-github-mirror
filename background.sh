#!/bin/bash

touch log.log
tail -f log.log -n 0 --pid $$ &
bash update-mirror.sh >> log.log 2>> log.log
