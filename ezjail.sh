#!/bin/sh
#
# $FreeBSD$
#
# PROVIDE: ezjail
# REQUIRE: LOGIN cleanvar
# BEFORE: securelevel
# KEYWORD: nojail shutdown
#
# Add the following lines to /etc/rc.conf.local or /etc/rc.conf to enable ezjail
#
#ezjail_enable="YES"
#
# Please do not change this file, configure in EZJAIL_PREFIX/etc/ezjail.conf

# ugly: this variable is set on port install time
ezjail_prefix=EZJAIL_PREFIX

. /etc/rc.subr

name=ezjail
rcvar=`set_rcvar`
extra_commands="startcrypto stopcrypto"
load_rc_config ${name}

ezjail_enable=${ezjail_enable:-"NO"}

restart_cmd="do_cmd restart _"
start_cmd="do_cmd start '_ ezjail'"
stop_cmd="do_cmd stop '_ ezjail'"
startcrypto_cmd="do_cmd startcrypto _"
stopcrypto_cmd="do_cmd stopcrypto _"

do_cmd()
{
  action=$1; message=$2; shift 2;
  ezjail_list=
  ezjail_pass=
  ezjail_mds=
  ezjail_fromrc="YES"

  # If a jail list is given on command line, process it
  # If not, fetch it from our config directory
  if [ -n "$*" ]; then
    ezjail_list=`echo -n $* | tr -c "[:alnum:] " _` 
    ezjail_fromrc="NO"
  else
    ezjail_list=${ezjail_list:-`ls ${ezjail_prefix}/etc/ezjail/`}
    echo -n "${message##_}"
  fi

  for ezjail in ${ezjail_list}; do
    # If jail is temporary disabled (dot in name), skip it
    [ ${ezjail%.*} = ${ezjail} ] || continue

    # Check for jails config
    [ ! -r ${ezjail_prefix}/etc/ezjail/${ezjail} ] && echo " Warning: Jail ${ezjail} not found." && continue

    # Read config file
    . ${ezjail_prefix}/etc/ezjail/${ezjail}

    eval ezjail_root=\"\$jail_${ezjail}_rootdir\"
    eval ezjail_image=\"\$jail_${ezjail}_image\"
    eval ezjail_crypt=\"\$jail_${ezjail}_cryptimage\"

    # Cannot auto mount crypto jails without interrupting boot process
    [ "${ezjail_fromrc}" = "YES" -a "${ezjail_crypt}" = "YES" -a "${action}" = "start" ] && continue

   # Explicitely do only run crypto jails when *crypto is requested
    [ "${action%crypto}" != "${action}" -a "${ezjail_crypt}" != "YES" ] && continue

    # Try to attach (crypto) devices
    [ "${ezjail_image}" ] && attach_detach_pre

    ezjail_pass="${ezjail_pass} ${ezjail}"
  done

  # Pass control to jail script which does the actual work
  [ "${ezjail_pass}" ] && sh /etc/rc.d/jail one${action%crypto} ${ezjail_pass}

  # Can only detach after unmounting (from fstab.JAILNAME in /etc/rc.d/jail)
  attach_detach_post
}

attach_detach_pre ()
{
  if [ "${action%crypto}" = "start" ]; then
    # If jail is running, do not mount devices, this is the same check as
    # /etc/rc.d/jail does
    [ -e /var/run/jail_${ezjail}.id ] && return

    # Create a memory disc from jail image
    ezjail_device=`mdconfig -a -t vnode -f ${ezjail_image}`

    # If this is a crypto jail, try to mount it, remind user, which jail
    # this is. In this case, the device to mount is 
    if [ "${ezjail_crypt}" = "YES" ]; then
      echo "Attaching gbde device for image jail ${ezjail}..."
      gbde attach /dev/${ezjail_device} -l ${ezjail_image%.img}.lock

      # Device to mount is not md anymore
      ezjail_device=${ezjail_device}.bde
    fi

    # relink image device
    rm -f ${ezjail_root}.device
    ln -s /dev/${ezjail_device} ${ezjail_root}.device
  else
    # If soft link to device is not set, we cannot unmount
    [ -e ${ezjail_root}.device ] || return

    # Fetch destination of soft link
    ezjail_device=`stat -f "%Y" ${ezjail_root}.device`

    # Add this device to the list of devices to be unmounted
    ezjail_mds="${ezjail_mds} ${ezjail_device%.bde}"

    # Remove soft link (which acts as a lock)
    rm -f ${ezjail_root}.device
  fi
}

attach_detach_post () {
  # In case of a stop, unmount image devices after stopping jails
  for md in ${ezjail_mds}; do
    [ -e ${md}.bde ] && gbde detach ${md}
    mdconfig -d -u ${md#/dev/}
  done
}

run_rc_command $*
