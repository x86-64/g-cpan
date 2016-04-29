#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

git pull
make clean-everything all && \
	git add --all ../ &&
	git commit -a -m "Update" --author "g_cpan <g-cpan@server.com>" &&
	git push
