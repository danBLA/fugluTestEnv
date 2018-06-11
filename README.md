# fugluTestEnv
Dockerfile to create fuglu test environment image

Based on centos:centos7 docker image this Dockerfile creates an image
which :

- contains all python modules (Py2/3) to install and run fuglu
- installs clamd and runs freshclam
- adds user clamav and freshclam
- installs spamd
- script '/usr/local/bin/start-services' to start clamav and spamd in background, waiting for services to be up and running
