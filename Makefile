# I know, this is ain't nice but an empty prefix leads to much confusion
# In most cases ezjail is being installed from ports anyway. If you REALLY REALLY
# want / as your install location, DO set PREFIX before invoking this Makefile

PREFIX?=/usr/local

all:

install:
	mkdir -p ${PREFIX}/etc/ezjail/ ${PREFIX}/man/man1/ ${PREFIX}/man/man5/ ${PREFIX}/etc/rc.d/ ${PREFIX}/bin/ ${PREFIX}/share/examples/ezjail
	cp -p ezjail.conf.sample ${PREFIX}/etc/
	cp -R -p examples/example ${PREFIX}/share/examples/ezjail/
	cp -R -p examples/nullmailer-example ${PREFIX}/share/examples/ezjail/
	sed s:EZJAIL_PREFIX:${PREFIX}: ezjail.sh > ${PREFIX}/etc/rc.d/ezjail.sh
	sed s:EZJAIL_PREFIX:${PREFIX}: ezjail-admin > ${PREFIX}/bin/ezjail-admin
	sed s:EZJAIL_PREFIX:${PREFIX}: man8/ezjail-admin.8 > ${PREFIX}/man/man8/ezjail-admin.8
	sed s:EZJAIL_PREFIX:${PREFIX}: man5/ezjail.conf.5 > ${PREFIX}/man/man5/ezjail.conf.5
	sed s:EZJAIL_PREFIX:${PREFIX}: man7/ezjail.7 > ${PREFIX}/man/man7/ezjail.7
	chmod 755 ${PREFIX}/etc/rc.d/ezjail.sh ${PREFIX}/bin/ezjail-admin
	chown -R root:wheel ${PREFIX}/man/man8/ezjail-admin.8 ${PREFIX}/man/man5/ezjail.conf.5 ${PREFIX}/man/man7/ezjail.7 ${PREFIX}/share/examples/ezjail/
	chmod 0440 ${PREFIX}/share/examples/ezjail/example/usr/local/etc/sudoers
