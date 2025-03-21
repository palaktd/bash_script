#!/bin/bash

# ---------------------------------------------------------------------------------------------------------
# Author: Murali Krishna Karanam

# Script to remove all the users who's inactive state is more than 30 days, using bash
#
# Coder API reference: https://coder.com/docs/v2/latest/api/users
#
# --------------------------------------------------------------------------------------------------------

domain="cdw.i.mercedes-benz.com"
inactive_days="30"

#CURL command to communicate with coder API to get list of users
data=$(curl -s -X GET "https://$domain/api/v2/users" -H 'Accept: application/json' -H "Coder-Session-Token: $1")

#Store the output in one json file
touch userdata.json
echo "$data" > userdata.json

#Assign output file name to variable to filter the data
input_file="userdata.json"

#variable declared to find final user count to be suspended.
usercount=0

while read username last_seen_at status ; do
        #remove ',' from user name
        user=$(echo $username | tr ',' ' ' | sed 's/ *$//g')

        #remove ',' from last_seen_at
        last_login_date_string=$(echo $last_seen_at | tr ',' ' ')

        current="$(date '+%s')"
        last_login_date="$(date -d "$last_login_date_string" '+%s')"
        diff_days=$(( ("$current" - "$last_login_date") / (3600 * 24) ))

        #Condition to chek the date difference
        if [ $diff_days -gt $inactive_days ] && [ "$status" = "active" ]
        then
                echo
                echo "-------------------------------------------------------------------------------"
                echo "$user accessed CDW $diff_days days ago. Hence Suspending $user."
                usercount=$(( $usercount + 1 ))

                $(curl -s -X PUT "https://$domain/api/v2/users/$user/status/suspend" -H 'Accept: application/json' -H "Coder-Session-Token: $1") &> /dev/null

                echo "$user has been suspended successfully!!!"
                echo "-------------------------------------------------------------------------------"
                echo
        fi

done < <(jq -r '.users[] | "\(.username), \(.last_seen_at), \(.status)"' "$input_file")

echo
echo "-------------------------------------------------------------------------------"
if [ $usercount = 0 ]
then
        echo "There are no users with an inactive status exceeding $inactive_days days."
else
        echo "Total no. of users suspended - $usercount."
fi
echo "-------------------------------------------------------------------------------"

#CLean the space by deleting the created file. 
rm -rf $input_file
#End of the script