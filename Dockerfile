FROM centos:centos7

MAINTAINER danBLA <danBLA@users.noreply.github.com>

# ssdeep -> see http://python-ssdeep.readthedocs.io/en/latest/installation.html#install-on-centos-7
#        => NOTE: not all versions working...
RUN yum  -y groupinstall "Development Tools"
RUN yum  -y install epel-release
RUN yum  -y install clamav clamav-scanner clamav-update clamav-data spamassassin python-magic git python-setuptools python-nose unar python-sqlalchemy python-pip postfix python36 python36-nose python36-pip libffi-devel python-devel python-pip ssdeep-devel ssdeep-libs python36-devel wget libxml2 python2-cryptography python36-cryptography
#unfortunately, unrar is no longer available in EPEL https://github.com/fumail/fuglu/issues/87
#RUN yum -y install ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/Kenzy:/modified:/C7/CentOS_7/x86_64/unrar-5.0.12-2.1.x86_64.rpm
RUN wget https://www.rarlab.com/rar/rarlinux-x64-5.6.0.tar.gz; tar -zxf rarlinux-x64-5.6.0.tar.gz; cd rar; cp -v rar unrar /usr/local/bin/; cd -
RUN yum update -y
RUN pip2 install --upgrade pip 'setuptools>=20.2.2'
# ssdeep==3.3 and smaller doesn't work for Python2
RUN pip2 install rarfile mock dkimpy dnspython pydns pyspf==2.0.12t ipaddr rednose ssdeep==3.2 redis geoip2 beautifulsoup4 lxml pysrs pylzma
RUN pip3 install --upgrade pip 'setuptools>=20.2.2'
RUN pip3 install rarfile rednose  sqlalchemy python-magic pyspf py3dns mock ssdeep redis geoip2 beautifulsoup4 lxml pysrs pylzma
# Install current domainmagic version for python 2/3
RUN wget https://gitlab.com/fumail/domainmagic/-/archive/master/domainmagic-master.zip; unzip -e domainmagic-master.zip; cd domainmagic-master/; python setup.py install --force; python3 setup.py install --force; cd -; rm -rf domainmagic-master domainmagic-master.zip
ADD freshclam.conf /etc/freshclam.conf
ADD clamd.conf /etc/clamd.conf
RUN adduser clamav && freshclam
ADD start-services.sh /usr/local/bin/start-services.sh
# update virus definitions (atm it is getting stuck 7.3.2019, so skip)
#RUN /usr/local/bin/start-services.sh freshclam

CMD ["/bin/bash"]
VOLUME /fuglu-src

EXPOSE 10025 10026 10888


