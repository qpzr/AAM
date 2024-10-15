#!/bin/bash

source /etc/profile
set -o errexit

cd "$(cd "$(dirname "$0")"; pwd)"
[ -e './raw-sources' ] && rm -rf ./raw-sources
mkdir ./raw-sources
rm -rf ./origin-files/upstream-*.txt

easylist=(
  'https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjx-annoyance.txt'
  'https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_224_Chinese/filter.txt'
  'https://raw.githubusercontent.com/easylist/easylist/gh-pages/easyprivacy.txt'
  'https://raw.githubusercontent.com/AdguardTeam/cname-trackers/master/data/combined_original_trackers.txt'
  'https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_11_Mobile/filter.txt'
  'https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/Filters/exceptions.txt'

)

# The script uses '^[a-zA-Z0-9\.-]+\.[a-zA-Z]+$' to match a domain in many cases
# Some punny code (top) domains, like 'example.xn--q9jyb4c', will be ignored

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

Hosts-Processer() {
	sed -e 's/[[:space:]]*#.*//g' -e 's/[[:space:]][[:space:]][[:space:]]*/ /g' -e 's/0\.0\.0\.0/127.0.0.1/g' -e 's/::/127.0.0.1/g' |
		grep -E '^127\.0\.0\.1 [a-zA-Z0-9\.-]+\.[a-zA-Z]+$' | LC_ALL=C sort -u
}

for i in "${!hosts[@]}"; do
	echo "Start to download hosts-${i}..."
	tMark="$(date +'%Y-%m-%d %H:%M:%S %Z')"
	curl -o "./raw-sources/hosts-${i}.txt" --connect-timeout 60 -s "${hosts[$i]}"
	echo -e "# hosts-${i} $tMark\n# ${hosts[$i]}" >>./origin-files/upstream-hosts.txt
	tr -d '\r' <"./raw-sources/hosts-${i}.txt" | Hosts-Processer >>./origin-files/upstream-hosts.txt
done

echo "Start to download $ACL4SSR_BanAD_URL"
tMark="$(date +'%Y-%m-%d %H:%M:%S %Z')"
curl --connect-timeout 60 -s -o - "$ACL4SSR_BanAD_URL" | tr -d '\r' |
	grep -E '^DOMAIN-SUFFIX,[a-zA-Z0-9\.-]+\.[a-zA-Z]+$' |
	sed -r 's/^DOMAIN-SUFFIX,/127.0.0.1 /' >./raw-sources/hosts-ACL4SSR-BanAD.txt
echo -e "# hosts-ACL4SSR-BanAD $tMark\n# $ACL4SSR_BanAD_URL" >>./origin-files/upstream-hosts.txt
LC_ALL=C sort -u ./raw-sources/hosts-ACL4SSR-BanAD.txt >>./origin-files/upstream-hosts.txt

echo "Start to download $ACL4SSR_BanProgramAD_URL"
tMark="$(date +'%Y-%m-%d %H:%M:%S %Z')"
curl --connect-timeout 60 -s -o - "$ACL4SSR_BanProgramAD_URL" | tr -d '\r' |
	grep -E '^DOMAIN-SUFFIX,[a-zA-Z0-9\.-]+\.[a-zA-Z]+$' |
	sed -r 's/^DOMAIN-SUFFIX,/127.0.0.1 /' >./raw-sources/hosts-ACL4SSR-BanProgramAD.txt
echo -e "# hosts-ACL4SSR-BanProgramAD $tMark\n# $ACL4SSR_BanProgramAD_URL" >>./origin-files/upstream-hosts.txt
LC_ALL=C sort -u ./raw-sources/hosts-ACL4SSR-BanProgramAD.txt >>./origin-files/upstream-hosts.txt

echo "Start to download $V2Fly_DLC_URL"
tMark="$(date +'%Y-%m-%d %H:%M:%S %Z')"
wget -qO ./raw-sources/geodata.tar.gz "$V2Fly_DLC_URL"
tar -xzf ./raw-sources/geodata.tar.gz -C ./raw-sources
cat ./raw-sources/domain-list-community-master/data/*-ads | tr -d '\r' |
	grep -E '^(full:)?([a-zA-Z0-9\.-]+\.[a-zA-Z]+)(\s+@ads)?$' |
	sed -r 's/^(full:)?([a-zA-Z0-9\.-]+\.[a-zA-Z]+)([[:space:]]*@ads)?$/127.0.0.1 \2/' >./raw-sources/hosts-v2fly-dlcads.txt
rm -rf ./raw-sources/geodata.tar.gz ./raw-sources/domain-list-community-master
echo -e "# hosts-v2fly-dlcads $tMark\n# $V2Fly_DLC_URL" >>./origin-files/upstream-hosts.txt
LC_ALL=C sort -u ./raw-sources/hosts-v2fly-dlcads.txt >>./origin-files/upstream-hosts.txt

tr -d '\r' <./origin-files/anti-ad-origin-block.txt >./raw-sources/hosts-origin-block.txt
echo -e "# hosts-origin-block $tMark\n# ./scripts/origin-files/anti-ad-origin-block.txt @adlist-maker" >>./origin-files/upstream-hosts.txt
Hosts-Processer <./raw-sources/hosts-origin-block.txt >>./origin-files/upstream-hosts.txt

tr -d '\r' <./origin-files/yhosts-latest.txt >./raw-sources/hosts-yhosts.txt
echo -e "# hosts-yhosts-latest $tMark\n# ./scripts/origin-files/yhosts-latest.txt @adlist-maker" >>./origin-files/upstream-hosts.txt
Hosts-Processer <./raw-sources/hosts-yhosts.txt >>./origin-files/upstream-hosts.txt

for i in "${!strict_hosts[@]}"; do
	echo "Start to download strict_hosts-${i}..."
	tMark="$(date +'%Y-%m-%d %H:%M:%S %Z')"
	curl -o "./raw-sources/strict-hosts-${i}.txt" --connect-timeout 60 -s "${strict_hosts[$i]}"
	echo -e "# strict_hosts-${i} $tMark\n# ${strict_hosts[$i]}" >>./origin-files/upstream-strict-hosts.txt
	tr -d '\r' <"./raw-sources/strict-hosts-${i}.txt" | Hosts-Processer >>./origin-files/upstream-strict-hosts.txt
done

for i in "${!dead_hosts[@]}"; do
	echo "Start to download dead_hosts-${i}..."
	tMark="$(date +'%Y-%m-%d %H:%M:%S %Z')"
	curl -o "./raw-sources/dead-hosts-${i}.txt" --connect-timeout 60 -s "${dead_hosts[$i]}"
	echo -e "# dead_hosts-${i} $tMark\n# ${dead_hosts[$i]}" >>./origin-files/upstream-dead-hosts.txt
	tr -d '\r' <"./raw-sources/dead-hosts-${i}.txt" | grep -E '^[a-zA-Z0-9\.-]+\.[a-zA-Z]+$' |
		LC_ALL=C sort -u >>./origin-files/upstream-dead-hosts.txt
done

tr -d '\r' <./origin-files/some-else.txt >./raw-sources/dead-hosts-some-else.txt
echo -e "# dead_hosts-some-else $tMark\n# ./scripts/origin-files/some-else.txt @adlist-maker" >>./origin-files/upstream-dead-hosts.txt
grep -E '^[a-zA-Z0-9\.-]+\.[a-zA-Z]+$' ./raw-sources/dead-hosts-some-else.txt | LC_ALL=C sort -u >>./origin-files/upstream-dead-hosts.txt

# Comment next line to track raw sources lists
rm -rf ./raw-sources/

sed -r -e '/^!/d' -e 's=^\|\|?=||=' ./origin-files/upstream-easylist.txt |
	grep -E '^\|\|[a-zA-Z0-9\.-]+\.[a-zA-Z]+\^(\$[^~]+)?$' | LC_ALL=C sort -u >./origin-files/base-src-easylist.txt
sed -r -e '/^!/d' -e 's=^\|\|?=||=' ./origin-files/upstream-easylist.txt |
	grep -E '\|\|([a-zA-Z0-9\.\*-]+)?\*([a-zA-Z0-9\.\*-]+)?\^(\$[^~]+)?$' | LC_ALL=C sort -u >./origin-files/wildcard-src-easylist.txt
sed -r -e '/^!/d' -e 's=^@@\|\|?=@@||=' ./origin-files/upstream-easylist.txt |
	grep -E '^@@\|\|[a-zA-Z0-9\.-]+\.[a-zA-Z]+\^' | LC_ALL=C sort -u >./origin-files/whiterule-src-easylist.txt
sed '/^#/d' ./origin-files/upstream-hosts.txt | LC_ALL=C sort -u >./origin-files/base-src-hosts.txt
sed '/^#/d' ./origin-files/upstream-strict-hosts.txt | LC_ALL=C sort -u >./origin-files/base-src-strict-hosts.txt
sed '/^#/d' ./origin-files/upstream-dead-hosts.txt | LC_ALL=C sort -u >./origin-files/base-dead-hosts.txt

cd ../

php make-addr.php
echo
php ./tools/easylist-extend.php ../anti-ad-easylist.txt
