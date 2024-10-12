#!/bin/bash

source /etc/profile

cd $(cd "$(dirname "$0")";pwd)

php make-addr.php
echo
php ./tools/easylist-extend.php ../anti-ad-easylist.txt
