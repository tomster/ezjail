#!/bin/sh

if [ -f /etc/ezjail.template ]; then
  . /etc/ezjail.template

  # we do need to install only once
  # rm /etc/ezjail.template
fi

# set defaults
ezjail_template_root=${ezjail_template_root:-"/basejail/config/_JAILNAME_"}
ezjail_template_files=${ezjail_template_files:-""}
ezjail_template_users=${ezjail_template_users:-""}
ezjail_template_packages=${ezjail_template_packages:-""}

# try to create users
for user in $ezjail_template_users; do
  TIFS=$IFS; IFS=:; set -- $user; IFS=$TIFS
  if [ $# -eq 7 ]; then
    name=$1; grouplist=$3; gidlist=$4

    [ $2 ] && uid="-u $2"  || uid=""
    [ $5 ] && pass=$5 || pass="*"
    [ $6 ] && home=$6
    [ $7 ] && shell="-s $7"

    [ x$6 = x${6#-} ] && mkhome="-r" || mkhome=""; home=${6#-}
    [ $home ] && home="-h $home";

    if [ $grouplist ]; then
      gc=1
      for $group in `echo $grouplist | tr "," " "`; do
        gid=`echo $gidlist | cut -d , -f $gc`; [ $gid ] && gid="-n $gid"
        echo pw groupadd -n $group $gid
        gc=(($gc + 1))
      done
    endif
    if [ $name ]; then
      echo pw useradd $name $uid $shell $home $grouplist
    fi
  fi

done
