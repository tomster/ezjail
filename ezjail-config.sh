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

# try to create users
for user in $ezjail_flavour_users; do
  TIFS=$IFS; IFS=:; set -- $user; IFS=$TIFS
  if [ $# -eq 8 ]; then
    gc=1; name=$1; grouplist=$3; gidlist=$4; home=$7

    [ $2 ] && uid="-u $2"       || uid=""
    [ $5 ] && comment="-c$5"    || comment=""
    [ $6 ] && pass="$6"         || pass="*"
    [ $8 ] && shell="-s $8"     || shell=""

    [ "$home" = "${home#-}" ] && mkhome="-m" || mkhome=""
    [ ${home#-} ] && home="-d ${home#-}" || home=""

    # ensure all groups
    if [ $grouplist ]; then
      for group in `echo $grouplist | tr "," " "`; do
        gid=`echo $gidlist | cut -d , -f $gc`; [ $gid ] && gid="-g $gid"
        pw groupadd -n $group $gid
        gc=$((1+$gc))
      done
    fi
    # create user
    [ $grouplist ] && grouplist="-G $grouplist"
    [ $name ] && echo "$pass" | pw useradd -n $name $uid $shell $mkhome $home $grouplist "`echo $comment | tr = ' '`" -H 0
  fi
done

# chmod all files not belonging to root
for file in $ezjail_flavour_files; do
  TIFS=$IFS; IFS=:; set -- $file; IFS=$TIFS
  set +o noglob
  if [ $# -eq 3 -a "$3" ]; then
    owner=$1; [ $2 ] && owner="$1:$2"
    for file in ./$3; do
      chown -R $owner /$file
    done
  fi
  set -o noglob
done

# install packages
set +o noglob
[ -d /pkg ] && PACKAGESITE=file:// pkg_add -r /pkg/*

# source post install script
[ -d /ezjail.postinstall ] && . /ezjail.postinstall

# Get rid off ourself
rm -rf /pkg /etc/rc.d/ezjail-config.sh /ezjail.postinstall
