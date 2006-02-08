#!/bin/sh

set -o noglob
if [ -f /ezjail.flavour ]; then
  . /ezjail.flavour

  # we do need to install only once delete here to avoid errors
  # in this script to prevent jail startup forever
  rm -f /ezjail.flavour
fi

# set defaults
ezjail_flavour_users=${ezjail_flavour_users:-""}
ezjail_flavour_files=${ezjail_flavour_files:-""}

# try to create users, variables named after pw useradd params
for user in ${ezjail_flavour_users}; do
  TIFS=${IFS}; IFS=:; set -- ${user}; IFS=${TIFS}
  if [ $# -eq 8 ]; then
    u=${2:+-u$2}; G=$3; gs=$4; c=${5:+-c$5}; p=${6:-*}; d=${7#-}; m=${7%%[!-]*}; s=${8:+-s$8};

    # ensure all groups
    gc=1; for n in `echo -n ${G} | tr , ' '`; do
      g=`echo -n ${gs} | cut -d , -f ${gc}`
      pw groupadd -q -n ${n} ${g:+-g${g}}
      gc=$((1+${gc}))
    done

    # create user
    [ $1 ] && echo ${p} | pw useradd -n $1 ${u} ${s} ${m:+-m} ${d:+-d${d}} ${G:+-G${G}} "`echo -n ${c} | tr = ' '`" -H 0
  fi
done
set +o noglob

# chmod all files not belonging to root
for file in ${ezjail_flavour_files}; do
  TIFS=${IFS}; IFS=:; set -- ${file}; IFS=${TIFS}
  [ $# -gt 2 ] && owner="$1:$2" && shift 2 && chown -R ${owner} $*
done

# install packages
[ -d /pkg ] && PACKAGESITE=file:// pkg_add -r /pkg/*

# source post install script
[ -d /ezjail.postinstall ] && . /ezjail.postinstall

# Get rid off ourself
rm -rf /pkg /etc/rc.d/ezjail-config.sh /ezjail.postinstall
