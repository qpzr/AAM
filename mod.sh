#!/bin/bash

source /etc/profile

cd $(cd "$(dirname "$0")";pwd)

easylist=(
  "https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjx-annoyance.txt"
  "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_224_Chinese/filter.txt"
  "https://raw.githubusercontent.com/easylist/easylist/gh-pages/easyprivacy.txt"
  "https://raw.githubusercontent.com/AdguardTeam/cname-trackers/master/data/combined_original_trackers.txt"
  "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_11_Mobile/filter.txt"
  "https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/Filters/exceptions.txt"

)

hosts=(
  "https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts"
)

rm -f ./origin-files/*.txt

for i in "${!easylist[@]}"
do
  echo "开始下载 easylist${i}..."
  curl -o "./origin-files/easylist${i}.txt" --connect-timeout 60 -s "${easylist[$i]}"
  # shellcheck disable=SC2181
  if [ $? -ne 0 ];then
    echo '下载失败，请重试'
    exit 1
  fi
done

for i in "${!dead_hosts[@]}"
do
  echo "开始下载 dead-hosts${i}..."
  curl -o "./origin-files/dead-hosts${i}.txt" --connect-timeout 60 -s "${dead_hosts[$i]}"
  # shellcheck disable=SC2181
  if [ $? -ne 0 ];then
    echo '下载失败，请重试'
    exit 1
  fi
done

for i in "${!hosts[@]}"
do
  echo "开始下载 hosts${i}..."
  curl -o "./origin-files/hosts${i}.txt" --connect-timeout 60 -s "${hosts[$i]}"
  # shellcheck disable=SC2181
  if [ $? -ne 0 ];then
    echo '下载失败，请重试'
    exit 1
  fi
done

cd origin-files

cat hosts*.txt | grep -v -E "^((#.*)|(\s*))$" \
 | grep -v -E "^[0-9\.:]+\s+(ip6\-)?(localhost|loopback)$" \
 | sed s/0.0.0.0/127.0.0.1/g | sed s/::/127.0.0.1/g | sort \
 | uniq >base-src-hosts.txt


cat dead-hosts*.txt | grep -v -E "^(#|\!)" \
 | sort \
 | uniq >base-dead-hosts.txt


cat easylist*.txt | grep -E "^\|\|[-0-9a-zA-Z\.:]+\^" | sort | uniq >base-src-easylist.txt
cat easylist*.txt | grep -E "^\|\|?([^\^=\/:]+)?\*([^\^=\/:]+)?\^" | sort | uniq >wildcard-src-easylist.txt
cat easylist*.txt | grep -E "^@@\|\|?[^\^=\/:]+?\^([^\/=\*]+)?$" | sort | uniq >whiterule-src-easylist.txt

cd ../

php make-addr.php
echo
php ./tools/easylist-extend.php ../anti-ad-easylist.txt
