#!/bin/bash
#running systemd in docker vm doesn't work yet, so we need to start the daemons manually

wait_for_file () {
   if [ -z "$1" ];  then
      echo "wait_for_file: 1st argument is missing!"
      exit 1
   fi

   if [ -z "$2" ];  then
      echo "wait_for_file: 2nd argument is missing!"
      exit 1
   fi

   if [ -z "$3" ];  then
      echo "wait_for_file: 3nd argument is missing!"
      exit 1
   fi

   counter=0
   maxcounter=$2
   while ! [ -s $1 ] && [ $counter -lt $maxcounter ] ; do
      echo "waiting... $3 secs [$counter/$maxcounter]"
      let counter=counter+1
      sleep $3
   done
   if ! [ $counter -lt $maxcounter ]; then
      echo "time limit reached!"
      exit 1
   fi
   echo "file $1 is not empty"
   cat $1
}

wait_for_socket () {
   if [ -z "$1" ];  then
      echo "wait_for_file: 1st argument is missing!"
      exit 1
   fi

   if [ -z "$2" ];  then
      echo "wait_for_file: 2nd argument is missing!"
      exit 1
   fi

   if [ -z "$3" ];  then
      echo "wait_for_file: 3nd argument is missing!"
      exit 1
   fi

   counter=0
   maxcounter=$2
   while ! [ -S $1 ] && [ $counter -lt $maxcounter ] ; do
      echo "waiting... $3 secs [$counter/$maxcounter]"
      let counter=counter+1
      sleep $3
   done
   if ! [ $counter -lt $maxcounter ]; then
      echo "time limit reached!"
      exit 1
   fi
   echo "socket $1 exists and open"
}


startClamd=0
startSpamd=0
startFuglu=0
runFreshclam=0
if [ -z $1 ]; then
   startClamd=1
   startSpamd=1
elif [ $1 == "all" ]; then
   startClamd=1
   startSpamd=1
   startFuglu=1
elif [ $1 == "allwithfreshclam" ]; then
   startClamd=1
   startSpamd=1
   startFuglu=1
   runFreshclam=1
elif [ $1 == "clamd" ]; then
   startClamd=1
elif [ $1 == "freshclam" ]; then
   runFreshclam=1
elif [ $1 == "clamdfreshclam" ]; then
   startClamd=1
   runFreshclam=1
elif [ $1 == "spamd" ]; then
   startSpamd=1
elif [ $1 == "fuglu" ]; then
   startFuglu=1
else
   echo "Error in command line arguments!"
   echo ""
   echo "USAGE: start-services.sh OPTIONS"
   echo "       with OPTIONS: (empty)          - start clamd and spamd (background)"
   echo "                      clamd           - start clamd (background)"
   echo "                      freshclam       - run freshclam to update ClamAV virus definitions"
   echo "                      clamdfreshclam  - start clamd (background) after running freshclam"
   echo "                      spamd           - start spamd (background)"
   echo "                      fuglu           - start fuglu (foreground)"
   echo "                      all             - start fuglu (foreground), clamd and spamd (background)"
   echo "                                                                  and run freshclam"
   exit 1
fi

echo ""
echo "-----------------------------------"
echo "- Localhost aliases in /etc/hosts -"
echo "-----------------------------------"
echo ""
echo "127.0.0.1	clamd" >> /etc/hosts
echo "127.0.0.1	spamd" >> /etc/hosts


echo ""
echo "------------------------"
echo "- start-services: todo -"
echo "------------------------"
echo ""
if [ $runFreshclam -eq 1 ]; then
   echo "- run freshclam to update ClamAV virus definitions"
else
   echo "- (no clamAV virus definition update)"
fi
if [ $startClamd -eq 1 ]; then
   echo "- start clamd"
else
   echo "- (not starting clamd)"
fi
if [ $startSpamd -eq 1 ]; then
   echo "- start spamd"
else
   echo "- (not starting spamd)"
fi
if [ $startFuglu -eq 1 ]; then
   echo "- start fuglu"
else
   echo "- (not starting fuglu)"
fi
echo ""

# There seems to be a problem when running in privileged containers
# therefore to make this sript work in a docker-in-docker container
# the executable has to be moved from its original location to avoid
# an shared library access permission error, see
# https://github.com/moby/moby/issues/14140
# https://github.com/moby/moby/issues/5490
if [ -f /usr/bin/freshclam ]; then
   mv -f /usr/bin/freshclam /usr/local/bin/freshclam
fi

if [ -f /usr/sbin/clamd ]; then
   mv -f /usr/sbin/clamd /usr/local/bin/clamd
fi

if [ $runFreshclam -eq 1 ]; then

    echo "update clamd virus definitions"
    # sleep for one second to avoid "text file busy" - problem
    # https://github.com/moby/moby/issues/9547
    sleep 1
    /usr/local/bin/freshclam
fi

if [ $startClamd -eq 1 ]; then
    mkdir -p /var/run/clamav
    chmod a=rwx /var/run/clamav

    createlog=1
    if [ "$1" = "nolog" ];  then
       echo "no log file will be created and no wait operation performed"
       let createlog=0
    fi

    if [ -z "$(ps -ef | grep -i 'clamd' | tail -n +2)" ]; then
       echo "clamd not running"
       sleep 1

       if [ $createlog -eq 1 ]; then
          /usr/local/bin/clamd -c /etc/clamd.conf --foreground=yes > clamd.log 2>&1 &
          # wait for something to apper in the log file
          # args: filename, number of tries, time to wait between tries
          wait_for_file clamd.log 360 5
          wait_for_socket /var/run/clamav/clamd.ctl 360 5
       else
          echo "start clamd without waiting"
          /usr/local/bin/clamd -c /etc/clamd.conf --foreground=yes > /dev/null 2>&1 &
       fi
    else
       echo "clamd is already running..."
    fi
fi

if [ $startSpamd -eq 1 ]; then
    if [ -z "$(ps -ef | grep -i 'spamd' | tail -n +2)" ]; then
       echo "spamd not running"

       if [ $createlog -eq 1 ]; then
          spamd  > spamd.log 2>&1 &
          # wait for something to apper in the log file
          # args: filename, number of tries, time to wait between tries
          wait_for_file spamd.log 360 5
       else
          echo "start spamd without waiting"
          spamd  > /dev/null 2>&1 &
       fi
    else
       echo "spamd is already running..."
    fi
fi

if [ $startFuglu -eq 1 ]; then
    if [ -z "$(ps -ef | grep -i 'fuglu' | tail -n +2)" ]; then
       echo "starting fuglu"
       /usr/bin/fuglu --foreground
       exit $?
    else
       echo "fuglu is already running..."
    fi
fi

exit 0

