all:

install:
	mkdir -p ${PREFIX}/etc/ezjail/ ${PREFIX}/man/man1 ${PREFIX}/man/man5
	cp -p ezjail.conf.sample ${PREFIX}/etc/
	sed s:EZJAIL_PREFIX:${PREFIX}: ezjail.sh > ${PREFIX}/etc/rc.d/ezjail.sh
	sed s:EZJAIL_PREFIX:${PREFIX}: ezjail-admin > ${PREFIX}/bin/ezjail-admin
	sed s:EZJAIL_PREFIX:${PREFIX}: man1/ezjail-admin.1 > ${PREFIX}/man/man1/ezjail-admin.1
	sed s:EZJAIL_PREFIX:${PREFIX}: man5/ezjail.conf.5 > ${PREFIX}/man/man5/ezjail.conf.5
	sed s:EZJAIL_PREFIX:${PREFIX}: man5/ezjail.5 > ${PREFIX}/man/man5/ezjail.5
	chmod 755 ${PREFIX}/etc/rc.d/ezjail.sh ${PREFIX}/bin/ezjail-admin
	chown root:wheel ${PREFIX}/man/man1/ezjail-admin.1 ${PREFIX}/man/man5/ezjail.conf.5 ${PREFIX}/man/man5/ezjail.5
