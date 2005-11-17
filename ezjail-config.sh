#!/bin/sh
#
# BEFORE: rcconf

if [ -f /etc/ezjail.flavour ]; then
  . /etc/ezjail.flavour

  # we do need to install only once
  # rm -f /etc/ezjail.flavour
fi

# set defaults
ezjail_flavour_root=${ezjail_flavour_root:-"/basejail/config/default"}
ezjail_flavour_files=${ezjail_flavour_files:-""}
ezjail_flavour_users=${ezjail_flavour_users:-""}
ezjail_flavour_packages=${ezjail_flavour_packages:-""}

# try to create users
for user in $ezjail_flavour_users; do
  TIFS=$IFS; IFS=:; set -- $user; IFS=$TIFS

  if [ $# -eq 8 ]; then
    gc=1; name=$1; grouplist=$3; gidlist=$4; home=$7

    [ $2 ] && uid="-u $2"       || uid=""
    [ $5 ] && comment="-c \"`echo $5 | tr _ ' '`\""   || comment=""
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
    [ $name ] && echo "$pass" | pw useradd -n $name $uid $shell $mkhome $home $grouplist $comment -H 0
  fi
done

# try to install files
cd $ezjail_flavour_root
for file in $ezjail_flavour_files; do
  TIFS=$IFS; IFS=:; set -- $file; IFS=$TIFS

  if [ $# -eq 3 -a "$3" ]; then
    owner=$1; [ $2 ] && owner="$1:$2"
    for file in $3; do
      find ${file#/} | cpio -p -l -d /
      chown -R $owner $file
    done
  fi
done

# finally install packages
[ -d /basejail/config/pkg ] && cd /basejail/config/pkg
[ $ezjail_flavour_packages ] && pkg_add $ezjail_flavour_packages

# Get rid off ourself
rm -f /etc/rc.d/ezjail-config.sh
