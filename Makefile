# I know, this is ain't nice but an empty prefix leads to much confusion
# In most cases ezjail is being installed from ports anyway. If you REALLY REALLY
# want / as your install location, DO set PREFIX before invoking this Makefile

PREFIX?=/usr/local

all:

install:
	mkdir -p ${PREFIX}/etc/ezjail/ ${PREFIX}/man/man1/ ${PREFIX}/man/man5/ ${PREFIX}/etc/rc.d/ ${PREFIX}/bin/ ${PREFIX}/share/ezjail ${PREFIX}/share/examples/ezjail
	cp -p ezjail.conf.sample ${PREFIX}/etc/
	cp -p ezjail-config.sh ${PREFIX}/share/ezjail/
	cp -p examples/ezjail.flavour.default ${PREFIX}/share/examples/ezjail/
	sed s:EZJAIL_PREFIX:${PREFIX}: ezjail.sh > ${PREFIX}/etc/rc.d/ezjail.sh
	sed s:EZJAIL_PREFIX:${PREFIX}: ezjail-admin > ${PREFIX}/bin/ezjail-admin
	sed s:EZJAIL_PREFIX:${PREFIX}: man1/ezjail-admin.1 > ${PREFIX}/man/man1/ezjail-admin.1
	sed s:EZJAIL_PREFIX:${PREFIX}: man5/ezjail.conf.5 > ${PREFIX}/man/man5/ezjail.conf.5
	sed s:EZJAIL_PREFIX:${PREFIX}: man5/ezjail.5 > ${PREFIX}/man/man5/ezjail.5
	chmod 755 ${PREFIX}/etc/rc.d/ezjail.sh ${PREFIX}/bin/ezjail-admin
	chown root:wheel ${PREFIX}/man/man1/ezjail-admin.1 ${PREFIX}/man/man5/ezjail.conf.5 ${PREFIX}/man/man5/ezjail.5
