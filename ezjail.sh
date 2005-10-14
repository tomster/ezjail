#/bin/sh

# $FreeBSD$
#
# PROVIDE: ezjail
#
# Note: Add the following lines to /etc/rc.conf to enable ezjail,
#
#ezjail_enable="YES"
#
# Please do not change this file, configure in EZJAIL_PREFIX/etc/ezjail.conf

# ugly: this variable is set on port install time
ezjail_prefix=EZJAIL_PREFIX

. /etc/rc.subr

name=ezjail
rcvar=`set_rcvar`
load_rc_config $name

ezjail_enable=${ezjail_enable:-"NO"}

restart_cmd="do_restart"
start_cmd="do_start"
stop_cmd="do_stop"

do_start()
{
  [ -n "$*" ] && jail_list=`echo $* | tr /~. ___` || echo " ezjail"
  jail_list=${jail_list:-`ls ${ezjail_prefix}/etc/ezjail/`}
  for jail in $jail_list; do . ${ezjail_prefix}/etc/ezjail/${jail}; done
  sh /etc/rc.d/jail onestart $jail_list
}

do_restart()
{
  [ -n "$*" ] && jail_list=`echo $* | tr /~. ___`;
  jail_list=${jail_list:-`ls ${ezjail_prefix}/etc/ezjail/`}
  for jail in $jail_list; do . ${ezjail_prefix}/etc/ezjail/${jail}; done
  sh /etc/rc.d/jail onestop $jail_list
  sh /etc/rc.d/jail onestart $jail_list
}

do_stop()
{
  [ -n "$*" ] && jail_list=`echo $* | tr /~. ___` || echo " ezjail"
  jail_list=${jail_list:-`ls ${ezjail_prefix}/etc/ezjail/`}
  for jail in $jail_list; do . ${ezjail_prefix}/etc/ezjail/${jail}; done
  sh /etc/rc.d/jail onestop $jail_list
}

run_rc_command $*
