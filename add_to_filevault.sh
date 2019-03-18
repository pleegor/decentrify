#!/bin/bash

#This script will add local user to FileVault

loggedInUser=`ls -l /dev/console | awk '{ print $3 }'`
sudo fdesetup add -usertoadd $loggedInUser -inputplist < <path_to_institutional_cert.plist> -certificate <path_to_institutional_cert.plist> -norecoverykey

#Close terminal
sleep 10
osascript -e 'quit app "Terminal"'

sudo jamf policy
