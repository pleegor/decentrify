#!/bin/bash

#  Migrate to local account from Centrify
#
#  This script is designed to ubind machine using adleave utility, uninstall Centrify, remove a mobile user account and re-create
#  a local account with the same username and the password (based end-user input). Service account credentials are passed as encrypted variables
#  through script's parameters in JSS.
#
#  Credits to Bryson Tyrrell https://github.com/brysontyrrell/EncryptedStrings on credentials encryption.
#


SRV_USER_ENCRYPTED="$4"
SRV_PASS_ENCRYPTED="$5"
SALT="$6"
PASSPHRASE="$7"

# Decrypts service account and password
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "$SALT" -k "$PASSPHRASE"
}

#Store decrypted credentials as variable
SRV_ACCOUNT=$(DecryptString ${SRV_USER_ENCRYPTED})
SRV_CREDS=$(DecryptString ${SRV_PASS_ENCRYPTED})
echo "decrypting srv creds"

#Unbind machine from DC and remove Centrify
/usr/local/share/centrifydc/libexec/adleave -r --user $SRV_ACCOUNT --password $SRV_CREDS
echo "Left domain"

#Uninstall Centrify
/bin/sh /usr/local/share/centrifydc/bin/uninstall.sh -n
echo "Centrify uninstalled"

#Gets the short name of the currently logged in user
loggedInUser=`ls -l /dev/console | awk '{ print $3 }'`
#Get loggedInUser UID
UserUID=`dscl . read /Users/"$loggedInUser" UniqueID | grep UniqueID: | cut -c 11-`
echo "Stored loggedInUser variable"

#Gets the real name of the currently logged in user
userRealName=`dscl . -read /Users/$loggedInUser | grep RealName: | cut -c11-`
if [[ -z $userRealName ]]; then
userRealName=`dscl . -read /Users/$loggedInUser | awk '/^RealName:/,/^RecordName:/' | sed -n 2p | cut -c 2-`
fi
echo "Stored RealName"

#Prompts user to enter their login password
loginPassword=`/usr/bin/osascript <<EOT
tell application "System Events"
activate
set myReply to text returned of (display dialog "Please enter your login password." ¬
default answer "" ¬
with title "YOUR TEAM" ¬
buttons {"Continue."} ¬
default button 1 ¬
with hidden answer)
end tell
EOT`

#Confirm password.
confirmPassword=`/usr/bin/osascript <<EOT
tell application "System Events"
activate
set myReply to text returned of (display dialog "Please confirm your password" ¬
default answer "" ¬
with title "YOUR TEAM" ¬
buttons {"Continue."} ¬
default button 1 ¬
with hidden answer)
end tell
EOT`

defaultPasswordAttempts=1

#Checks to ensure that enterd passwords match, if they don't -> it displays an error and prompts again.
while [ $loginPassword != $confirmPassword ] || [ -z $loginPassword ]; do
`/usr/bin/osascript <<EOT
tell application "System Events"
activate
display dialog "Passwords do not match. Please try again." ¬
with title "YOUR TEAM" ¬
buttons {"Continue."} ¬
default button 1
end tell
EOT`

loginPassword=`/usr/bin/osascript <<EOT
tell application "System Events"
activate
set myReply to text returned of (display dialog "Please enter your login password." ¬
default answer "" ¬
with title "YOUR TEAM" ¬
buttons {"Continue."} ¬
default button 1 ¬
with hidden answer)
end tell
EOT`

confirmPassword=`/usr/bin/osascript <<EOT
tell application "System Events"
activate
set myReply to text returned of (display dialog "Please confirm your password" ¬
default answer "" ¬
with title "YOUR TEAM" ¬
buttons {"Continue."} ¬
default button 1 ¬
with hidden answer)
end tell
EOT`

defaultPasswordAttempts=$((defaultPasswordAttempts+1))

if [[ $defaultPasswordAttempts -ge 5 ]]; then
`/usr/bin/osascript <<EOT
tell application "System Events"
activate
display dialog "You have entered mis-matching passwords five times. Please come to the IT desk for assistance." ¬
with title "YOUR TEAM" ¬
buttons {"Continue."} ¬
default button 1
end tell
EOT`
echo "Entered mis-matching passwords too many times."
exit 1
fi

done

#This will delete the currently logged in user
dscl . delete /Users/$loggedInUser

#Gets the current highest user UID and assigns new UID
maxid=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -ug | tail -1)
#New UID for the user
newid=$((maxid+1))
echo "Assigned NewUID"

#Gets the current highest user UID
maxid=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -ug | tail -1)
#Creating new UID for the user
newid=$((maxid+1))
echo "NewID"

#Creating the new user
dscl . -create /Users/"$loggedInUser"
dscl . -create /Users/"$loggedInUser" UserShell /bin/bash
dscl . -create /Users/"$loggedInUser" RealName "$userRealName"
dscl . -create /Users/"$loggedInUser" UniqueID "$newid"
dscl . -create /Users/"$loggedInUser" PrimaryGroupID 80
echo "Created new user"

#Set the user's password to the one entered prior
dscl . -passwd /Users/"$loggedInUser" "$loginPassword"
echo "Assigned password"

#Makes the user an admin
dscl . -append /Groups/admin GroupMembership "$loggedInUser"
echo "Added new user as admin"

#Reset ownership on home directory and append location
chown -R "$loggedInUser":staff /Users/"$loggedInUser"
dscl . -append /Users/"$loggedInUser" NFSHomeDirectory /Users/"$loggedInUser"/
echo "Changed user ownership to new user"

#Delete the user's keychain folder.
rm -Rf /Users/$loggedInUser/Library/Keychains/*
echo "Deleted old keychain"
echo "Bye bye Centrify; nothing beats freedom! Script was successfully executed."

#Forcing login
ps -Ajc | grep loginwindow | awk '{print $2}' | xargs kill -9
