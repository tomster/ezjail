all:

install:
	sed s:EZJAIL_PREFIX:${PREFIX}: ezjail > ${PREFIX}/etc/rc.d/ezjail
	chmod 755 ${PREFIX}/etc/rc.d/ezjail
	sed s:EZJAIL_PREFIX:${PREFIX}: ezjail-admin > ${PREFIX}/bin/ezjail-admin
	chmod 755 ${PREFIX}/bin/ezjail-admin
	cp -p ezjail.conf.sample ${PREFIX}/etc/
	mkdir -p ${PREFIX}/etc/ezjail/
