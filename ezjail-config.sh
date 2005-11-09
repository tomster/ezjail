#!/bin/sh
#
# BEFORE: rcconf

if [ -f /etc/ezjail.template ]; then
  . /etc/ezjail.template

  # we do need to install only once
  # rm -f /etc/ezjail.template
fi

# set defaults
ezjail_template_root=${ezjail_template_root:-"/basejail/config/default"}
ezjail_template_files=${ezjail_template_files:-""}
ezjail_template_users=${ezjail_template_users:-""}
ezjail_template_packages=${ezjail_template_packages:-""}

# try to create users
for user in $ezjail_template_users; do
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
cd $ezjail_template_root
for file in $ezjail_template_files; do
  TIFS=$IFS; IFS=:; set -- $file; IFS=$TIFS

  if [ $# -eq 3 -a "$3" ]; then
    owner=$1; [ $2 ] && owner="$1:$2"
    for file in $3; do
      find ${file#/} | cpio -p -d /
      chown -R $owner $file
    done
  fi
done

# finally install packages
[ -d /basejail/config/pkg ] && cd /basejail/config/pkg
[ $ezjail_template_packages ] && pkg_add $ezjail_template_packages

# Get rid off ourself
rm -f /etc/rc.d/ezjail-config.sh
