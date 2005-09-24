all:

install:
	mkdir -p ${PREFIX}/etc/ezjail/ ${PREFIX}/man/man1 ${PREFIX}/man/man5
	cp -p ezjail.conf.sample ${PREFIX}/etc/
	sed s:EZJAIL_PREFIX:${PREFIX}: ezjail > ${PREFIX}/etc/rc.d/ezjail
	sed s:EZJAIL_PREFIX:${PREFIX}: ezjail-admin > ${PREFIX}/bin/ezjail-admin
	sed s:EZJAIL_PREFIX:${PREFIX}: man1/ezjail-admin.1 > ${PREFIX}/man/man1/ezjail-admin.1
	sed s:EZJAIL_PREFIX:${PREFIX}: man5/ezjail.conf.5 > ${PREFIX}/man/man5/ezjail.conf.5
	sed s:EZJAIL_PREFIX:${PREFIX}: man1/ezjail.5 > ${PREFIX}/man/man5/ezjail.5
	chmod 744 ${PREFIX}/etc/rc.d/ezjail ${PREFIX}/bin/ezjail-admin
	chown root:wheel ${PREFIX}/man/man1/ezjail-admin.1 ${PREFIX}/man/man5/ezjail.conf.5 ${PREFIX}/man/man5/ezjail.5
