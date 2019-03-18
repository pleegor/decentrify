# Bye Bye Centrify


## What we wanted.

One of the biggest challenges for us in managing MacOS based clients was bind. We used Centrify in order instead of native bind tools in MacOS. At some point, we decided to utilize NoMAD Pro (which was recently acquired by JAMF) which sounded for us like a great solution that will allow us to utilize kerberos tickets with Okta for password management and at the same time stop binding MacOS devices directly to Active Directory. NoMAD Pro is a clever solution for many organizations, however, it does not support mobile accounts (created during domain join process by Centrify).

We also utilize JAMF for device management and we wanted to create a solution that will allows users to do the migration without assistance of our Support Team. At the same time since previously we used institutional keys for encryption; we had to find a way how to add allow users to add their local account back to filevault.


This is the logic we had:
1. Create a script that will allow to remove devices from Active Directory using ```adleave``` built-in utility in Centrify (because cleaning up AD manually for unused objects is PITA!).
2. Allow local user to be added to filevault as soon as user is logged out from mobile account.
3. Allow users to perform migration with minimal interaction with IT Support.    

## This is how we did it...

1. 1. We created a [script](https://github.com/pleegor/decentrify/blob/master/add_to_filevault.sh) that removed device from Active Directory utilizing service account (thanks to Bryson Tyrrel for finding a way to [encrypt](https://github.com/brysontyrrell/EncryptedStrings) credentials with JAMF parameters) and placed script in Self Service. 
2. Created JAMF payload that placed another [script](https://github.com/pleegor/decentrify/blob/master/add_to_filevault.sh) credentials to add user to filevault.
3. Placed a simple script to add newly created user (local account) to filevault on user's device
4. Created a simple in Self Service that called created script in previous step.
5. Added a payload that removed institutional keys at the next check-in (applicable to smart group with not installed Centrify app in group's criteria)




## Next Steps
Use Jamf Helper instead of osascript

## License
[MIT](https://choosealicense.com/licenses/mit/)
