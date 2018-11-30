#!/bin/bash

remote='s2:~/public_html/blang/'
chmod -R 755 www
rsync -t --rsh=/usr/bin/ssh --recursive --perms --group www/ $remote; echo "Finished pushing blang documentation site" &