#!/bin/sh

# ugly: this variable is set during port install time
#ezjail_prefix=EZJAIL_PREFIX
ezjail_prefix=/usr/local/
ezjail_etc=${ezjail_prefix}/etc
ezjail_share=${ezjail_prefix}/share/ezjail
ezjail_examples=${ezjail_prefix}/share/examples/ezjail
ezjail_jailcfgs=${ezjail_etc}/ezjail

# read user config
[ -f ${ezjail_etc}/ezjail.conf ] && . ${ezjail_etc}/ezjail.conf

# set defaults
ezjail_jaildir=${ezjail_jaildir:-"/usr/jails"}
ezjail_jailtemplate=${ezjail_jailtemplate:-"${ezjail_jaildir}/newjail"}
ezjail_jailbase=${ezjail_jailbase:-"${ezjail_jaildir}/basejail"}
ezjail_jailfull=${ezjail_jailfull:-"${ezjail_jaildir}/fulljail"}
ezjail_flavours=${ezjail_flavours:-"${ezjail_jaildir}/flavours"}
ezjail_sourcetree=${ezjail_sourcetree:-"/usr/src"}
ezjail_portscvsroot=${ezjail_portscvsroot:-":pserver:anoncvs@anoncvs.at.FreeBSD.org:/home/ncvs"}

ezjail_mount_enable=${ezjail_mount_enable:-"YES"}
ezjail_devfs_enable=${ezjail_devfs_enable:-"YES"}
ezjail_devfs_ruleset=${ezjail_devfs_ruleset:-"devfsrules_jail"}
ezjail_procfs_enable=${ezjail_procfs_enable:-"YES"}
ezjail_fdescfs_enable=${ezjail_fdescfs_enable:-"YES"}

# define our bail out shortcut
exerr () { echo -e "$*"; exit 1; }

# define detach strategy for image jails
detach_images () {
  # unmount and detach memory disc
  if [ "${newjail_img_device}" ]; then
    umount ${newjail_root}
    [ "${newjail_image}" = "crypto" ] && gbde detach /dev/${newjail_img_device}
    mdconfig -d -u ${newjail_img_device}
  fi
}

# check for command
[ "$1" ] || exerr "Usage: `basename -- $0` [create] {params}"

case "$1" in
######################## ezjail-admin CREATE ########################
create)
  shift
  args=`getopt f:r:s:xic $*` || exerr "Usage: `basename -- $0` create [-f flavour] [-r jailroot] [-s size] [-xic] jailname jailip"

  newjail_root=
  newjail_flavour=
  newjail_softlink=
  newjail_image=
  newjail_imagesize=
  newjail_device=
  newjail_fill="YES"

  set -- ${args}
  for arg do
    case ${arg} in
      -x) newjail_fill="NO"; shift;;
      -r) newjail_root="$2"; shift 2;;
      -f) newjail_flavour="$2"; shift 2;;
      -i) newjail_image="simple"; shift;;
      -s) newjail_imagesize="$2"; shift 2;;
      -c) newjail_image="crypto"; shift;;
      --) shift; break;;
    esac
  done
  newjail_name=$1; newjail_ip=$2   

  # we need at least a name and an ip for new jail
  [ "${newjail_name}" -a "${newjail_ip}" -a $# = 2 ] || exerr "Usage: `basename -- $0` create [-f flavour] [-r jailroot] [-x] jailname jailip"

  # check for sanity of settings concerning the image feature
  [ "${newjail_image}" -a "$newjail_fill" = "YES" -a ! "${newjail_imagesize}" ] && exerr "Image jails need an image size."

  # check, whether ezjail-update has been called. existence of
  # ezjail_jailbase is our indicator
  [ -d ${ezjail_jailbase} ] || exerr "Error: base jail does not exist. Please run 'ezjail-admin update' first."

  # relative paths don't make sense in rc.scripts
  [ "${ezjail_jaildir%%[!/]*}" ] || exerr "Error: Need an absolute path in ezjail_jaildir, it currently is set to: ${ezjail_jaildir}."

  # jail names must not irritate file systems, excluding dots from this list
  # was done intentionally to permit foo.com style directory names, however,
  # the jail name will be foo_com in most scripts

  newjail_name=`echo -n ${newjail_name} | tr /~ __`
  newjail_nname=`echo -n "${newjail_name}" | tr -c [:alnum:] _`
  newjail_root=${newjail_root:-"${ezjail_jaildir}/${newjail_name}"}

  # This scenario really will only lead to real troubles in the 'fulljail'
  # case, but I should still explain this to the user and not claim that
  # "an ezjail would already exist"
  [ "${newjail_nname}" = "basejail" -o "${newjail_nname}" = "newjail" -o "${newjail_nname}" = "fulljail" -o "${newjail_nname}" = "flavours" ] && \
    exerr "Error: ezjail needs the ${newjail_nname} directory for its own administrative purposes. Please rename the ezjail."

  # jail names may lead to identical configs, eg. foo.bar.com == foo-bar.com
  # so check, whether we might be running into problems
  [ -e ${ezjail_jailcfgs}/${newjail_nname} ] && exerr "Error: an ezjail config already exists at ${ezjail_jailcfgs}/${newjail_nname}. Please rename the ezjail."

  # if jail root specified on command line is not absolute, make it absolute
  # inside our jail directory
  [ "${newjail_root%%[!/]*}" ] || newjail_root=${ezjail_jaildir}/${newjail_root}

  # if a directory at the specified jail root already exists, refuse to
  # install
  [ -e ${newjail_root} -a "${newjail_fill}" = "YES" ] && exerr "Error: the specified jail root ${newjail_root} alread exists."

  # if jail root specified on command line does not lie within our jail
  # directory, we need to create a softlink
  if [ "${newjail_root##${ezjail_jaildir}}" = "${newjail_root}" ]; then
    newjail_softlink=${ezjail_jaildir}/`basename -- ${newjail_root}`
    [ -e ${newjail_softlink} -a "${newjail_fill}" = "YES" ] && exerr "Error: an ezjail already exists at ${newjail_softlink}."
  fi

  # do some sanity checks on the selected flavour (if any)
  [ "${newjail_flavour}" -a ! -d ${ezjail_flavours}/${newjail_flavour} ] && exerr "Error: Flavour config directory ${ezjail_flavours}/${newjail_flavour} not found."

  #
  # All sanity checks that may lead to errors are hopefully passed here
  #

  if [ "${newjail_image}" ]; then
    # Strip trailing slashes from jail root, those would confuse image path
    newjail_img=${newjail_root%/}; while [ "${newjail_img}" -a -z "${newjail_img%%*/}" ]; do newjail_img=${newjail_img%/}; done
    [ -z "${newjail_img}" ] && exerr "Error: Could not determine image file name, something is wrong with the jail root: ${newjail_root}."

    # Location of our image and crypto image lock file
    newjail_lock=${newjail_img}.lock
    newjail_img=${newjail_img}.img

    # If NOT exist, create image
    if [ "$newjail_fill" = "YES" ]; then
      [ -e "${newjail_img}" ] && exerr "Error: a file exists at the location ${newjail_img}, preventing our own image file to be created."
      [ "${newjail_image}" = "crypto" -a -e "${newjail_lock}" ] && exerr "Error: a file exists at the location ${newjail_lock}, preventing our own crypto image lock file to be created."

      # Now create jail disc image
      touch "${newjail_img}"
      dd if=/dev/random of="${newjail_img}" bs="${newjail_imagesize}" count=1 || exerr "Error: Could not (or not fully) create the image file. You might want to check (and possibly remove) the file ${newjail_img}. The image size provided was ${newjail_imagesize}."

      # And attach device
      newjail_img_device=`mdconfig -a -t vnode -f ${newjail_img}`

      if [ "${newjail_image}" = "crypto" ]; then
        # Initialise crypto image
        # XXX TODO: catch error and detach memory disc
        echo "Initialising crypto device. Enter a new passphrase twice..."
        gbde init /dev/${newjail_img_device} -L ${newjail_lock}

        # XXX TODO: catch error and detach memory disc
        echo "Attaching crypto device. Enter the passphrase..."
        gbde attach /dev/${newjail_img_device} -l ${newjail_lock}
        newjail_device=${newjail_img_device}.bde
      else
        newjail_device=${newjail_img_device}
      fi

      # Format memory image
      newfs /dev/${newjail_device}
      # Create mount point and mount
      mkdir -p ${newjail_root}
      mount /dev/${newjail_device} ${newjail_root}
    else
      [ -e ${newjail_root} -a ! -d ${newjail_root} ] && exerr "Error: Could not create mount point for your jail image. A file exists at its location. (For existing image jails, call this tool without the .img suffix when specifying jail root.)"
      [ -d ${newjail_root} ] || mkdir -p ${newjail_root}
    fi
  fi

  # now take a copy of our template jail
  if [ "${newjail_fill}" = "YES" ]; then
    mkdir -p ${newjail_root} && cd ${ezjail_jailtemplate} && find * | cpio -p -v ${newjail_root} > /dev/null
    [ $? = 0 ] || detach_images || exerr "Error: Could not copy template jail."
  fi

  # if a soft link is necessary, create it now
  [ "${newjail_softlink}" ] && ln -s ${newjail_root} ${newjail_softlink}  

  # if the automount feature is not disabled, this fstab entry for new jail
  # will be obeyed
  echo -n > /etc/fstab.${newjail_nname}
  [ "${newjail_image}" ] && \
  echo ${newjail_root}.device ${newjail_root} ufs rw 0 0 >> /etc/fstab.${newjail_nname}
  echo ${ezjail_jailbase} ${newjail_root}/basejail nullfs ro 0 0 >> /etc/fstab.${newjail_nname}

  # now, where everything seems to have gone right, create control file in  
  # ezjails config dir
  mkdir -p ${ezjail_jailcfgs}
  echo export jail_${newjail_nname}_hostname=\"${newjail_name}\" > ${ezjail_jailcfgs}/${newjail_nname}
  echo export jail_${newjail_nname}_ip=\"${newjail_ip}\" >> ${ezjail_jailcfgs}/${newjail_nname}
  echo export jail_${newjail_nname}_rootdir=\"${newjail_root}\" >> ${ezjail_jailcfgs}/${newjail_nname}
  echo export jail_${newjail_nname}_exec=\"/bin/sh /etc/rc\" >> ${ezjail_jailcfgs}/${newjail_nname}
  echo export jail_${newjail_nname}_mount_enable=\"${ezjail_mount_enable}\" >> ${ezjail_jailcfgs}/${newjail_nname}
  echo export jail_${newjail_nname}_devfs_enable=\"${ezjail_devfs_enable}\" >> ${ezjail_jailcfgs}/${newjail_nname}
  echo export jail_${newjail_nname}_devfs_ruleset=\"devfsrules_jail\" >> ${ezjail_jailcfgs}/${newjail_nname}
  echo export jail_${newjail_nname}_procfs_enable=\"${ezjail_procfs_enable}\" >> ${ezjail_jailcfgs}/${newjail_nname}
  echo export jail_${newjail_nname}_fdescfs_enable=\"${ezjail_fdescfs_enable}\" >> ${ezjail_jailcfgs}/${newjail_nname}
  [ "${newjail_image}" ] && \
  echo export jail_${newjail_nname}_image=\"${newjail_img}\" >> ${ezjail_jailcfgs}/${newjail_nname}
  [ "${newjail_image}" = "crypto" ] && \
  echo export jail_${newjail_nname}_cryptimage=\"YES\" >> ${ezjail_jailcfgs}/${newjail_nname}

  # Final steps for flavour installation   
  if [ "${newjail_fill}" = "YES" -a "${newjail_flavour}" ]; then
    # install files and config to new jail
    cd ${ezjail_flavours}/${newjail_flavour} && find * | cpio -p -v ${newjail_root} > /dev/null
    [ $? = 0 ] || echo "Warning: Could not fully install flavour."

    # If a config is found, make it auto run on jails startup
    if [ -f ${newjail_root}/ezjail.flavour ]; then
      ln -s /ezjail.flavour ${newjail_root}/etc/rc.d/ezjail-config.sh
      chmod 0700 ${newjail_root}/ezjail.flavour
      echo "Note: Shell scripts installed, flavourizing on jails first startup."
    fi
  fi

  # Detach (crypto and) memory discs
  detach_images

  #
  # For user convenience some scenarios commonly causing headaches are checked
  #

  # check, whether IP is configured on a local interface, warn if it isnt
  ping -c 1 -m 1 -t 1 -q ${newjail_ip} > /dev/null
  [ $? = 0 ] || echo "Warning: IP ${newjail_ip} not configured on a local interface."

  # check, whether some host system services do listen on the Jails IP
  TIFS=${IFS}; IFS=_
  newjail_listener=`sockstat -4 -l | grep ${newjail_ip}:[[:digit:]]`
  [ $? = 0 ] && echo -e "Warning: Some services already seem to be listening on IP ${newjail_ip}\n  This may cause some confusion, here they are:\n${newjail_listener}"

  newjail_listener=`sockstat -4 -l | grep \*:[[:digit:]]`
  [ $? = 0 ] && echo -e "Warning: Some services already seem to be listening on all IP, (including ${newjail_ip})\n  This may cause some confusion, here they are:\n${newjail_listener}"
  IFS=${TIFS}
  
  ;;
*)
  exerr "Usage: `basename -- $0` [create|delete|list|update] {params}"
  ;;
esac

