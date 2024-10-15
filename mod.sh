#!/bin/bash

source /etc/profile

cd $(cd "$(dirname "$0")";pwd)
[ -e './raw-sources' ] && rm -rf ./raw-sources
mkdir ./raw-sources
rm -f ./origin-files/*.txt

easylist=(
  "https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjx-annoyance.txt"
  "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_224_Chinese/filter.txt"
  "https://raw.githubusercontent.com/easylist/easylist/gh-pages/easyprivacy.txt"
  "https://raw.githubusercontent.com/AdguardTeam/cname-trackers/master/data/combined_original_trackers.txt"
  "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_11_Mobile/filter.txt"
  "https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/Filters/exceptions.txt"

)

for i in "${!easylist[@]}"; do
	echo "Start to download easylist-${i}..."
	tMark="$(date +'%Y-%m-%d %H:%M:%S %Z')"
	curl -o "./raw-sources/easylist-${i}.txt" --connect-timeout 60 -s "${easylist[$i]}"
	echo -e "! easylist-${i} $tMark\n! ${easylist[$i]}" >>./origin-files/upstream-easylist.txt
	tr -d '\r' <"./raw-sources/easylist-${i}.txt" |
		grep -E '^(@@)?\|\|?[a-zA-Z0-9\.\*-]+\.[a-zA-Z\*]+\^(\$[^=]+)?$' |
		sed -e "/\^\$elemhide$/d" -e "/\^\$generichide$/d" |
		LC_ALL=C sort -u >>./origin-files/upstream-easylist.txt
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

rm -rf ./raw-sources/

sed -r -e '/^!/d' -e 's=^\|\|?=||=' ./origin-files/upstream-easylist.txt |
	grep -E '^\|\|[a-zA-Z0-9\.-]+\.[a-zA-Z]+\^(\$[^~]+)?$' | LC_ALL=C sort -u >./origin-files/base-src-easylist.txt
sed -r -e '/^!/d' -e 's=^\|\|?=||=' ./origin-files/upstream-easylist.txt |
	grep -E '\|\|([a-zA-Z0-9\.\*-]+)?\*([a-zA-Z0-9\.\*-]+)?\^(\$[^~]+)?$' | LC_ALL=C sort -u >./origin-files/wildcard-src-easylist.txt
sed -r -e '/^!/d' -e 's=^@@\|\|?=@@||=' ./origin-files/upstream-easylist.txt |
	grep -E '^@@\|\|[a-zA-Z0-9\.-]+\.[a-zA-Z]+\^' | LC_ALL=C sort -u >./origin-files/whiterule-src-easylist.txt
#cat easylist*.txt | grep -E "^\|\|[a-zA-Z0-9\.-]+\.[a-zA-Z]+\^(\$[^~]+)?$" | sort | uniq >base-src-easylist.txt
#cat easylist*.txt | grep -E "\|\|([a-zA-Z0-9\.\*-]+)?\*([a-zA-Z0-9\.\*-]+)?\^(\$[^~]+)?$" | sort | uniq >wildcard-src-easylist.txt
#cat easylist*.txt | grep -E "^@@\|\|[a-zA-Z0-9\.-]+\.[a-zA-Z]+\^" | sort | uniq >whiterule-src-easylist.txt

cd ../

php make-addr.php
echo
php ./tools/easylist-extend.php ../anti-ad-easylist.txt
