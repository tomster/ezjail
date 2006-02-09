#!/bin/sh
#
# $FreeBSD$
#
# PROVIDE: ezjail
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
load_rc_config ${name}

ezjail_enable=${ezjail_enable:-"NO"}

restart_cmd="do_cmd restart _"
start_cmd="do_cmd start '_ ezjail'"
stop_cmd="do_cmd stop '_ ezjail'"

do_cmd()
{
  action=$1; message=$2; shift 2;
  [ -n "$*" ] && jail_list=`echo -n $* | tr -c "[:alnum:] " _` || echo -n "${message##_}"
  jail_list=${jail_list:-`ls ${ezjail_prefix}/etc/ezjail/`}
  jail_pass=
  for jail in ${jail_list}; do
    if [ -f ${ezjail_prefix}/etc/ezjail/${jail} ]; then
      . ${ezjail_prefix}/etc/ezjail/${jail}
      jail_pass="${jail_pass} ${jail}"
    else
      echo " Warning: Jail ${jail} not found."
    fi
  done
  [ ${jail_pass} ] && sh /etc/rc.d/jail one${action} ${jail_pass}
}

run_rc_command $*
