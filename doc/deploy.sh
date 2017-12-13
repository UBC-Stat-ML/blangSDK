#!/bin/bash

remote='s2:~/public_html/blang/'

# TODO: permissions!

rsync -t --rsh=/usr/bin/ssh --recursive --perms --group www $remote; echo "Finished pushing maven artifacts" &