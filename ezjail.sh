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
load_rc_config ${name}

ezjail_enable=${ezjail_enable:-"NO"}

restart_cmd="do_cmd restart _"
start_cmd="do_cmd start '_ ezjail'"
stop_cmd="do_cmd stop '_ ezjail'"

do_cmd()
{
  action=$1; message=$2; shift 2;
  ezjail_list=
  [ -n "$*" ] && ezjail_list=`echo -n $* | tr -c "[:alnum:] " _` || echo -n "${message##_}"
  ezjail_list=${ezjail_list:-`ls ${ezjail_prefix}/etc/ezjail/`}
  ezjail_pass=
  for ezjail in ${ezjail_list}; do
    if [ -f ${ezjail_prefix}/etc/ezjail/${ezjail} ]; then
      . ${ezjail_prefix}/etc/ezjail/${ezjail}
      ezjail_pass="${ezjail_pass} ${ezjail}"
    else
      echo " Warning: Jail ${ezjail} not found."
    fi
  done
  [ "${ezjail_pass}" ] && sh /etc/rc.d/jail one${action} ${ezjail_pass}
}

run_rc_command $*
