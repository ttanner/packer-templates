#!/bin/sh -e

source config.vm
test -n "$http_proxy" && echo "Acquire::http::Proxy \"$http_proxy\";" >> /etc/apt/apt.conf.d/30proxy
test -n "$ftp_proxy" && echo "Acquire::ftp::Proxy \"$ftp_proxy\";" >> /etc/apt/apt.conf.d/30proxy

out=/etc/profile.d/proxy.sh
touch $out
test -n "$http_proxy" && echo "export http_proxy=\"$http_proxy\"" >> $out
test -n "$https_proxy" && echo "export https_proxy=\"$https_proxy\"" >> $out
test -n "$ftp_proxy" && echo "export ftp_proxy=\"$ftp_proxy\"" >> $out
test -n "$no_proxy" && echo "export no_proxy=\"$no_proxy\"" >> $out
exit 0
