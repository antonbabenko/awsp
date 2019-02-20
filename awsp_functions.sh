#!/bin/bash

# @source - https://github.com/antonbabenko/awsp

function _awsListAll() {
    credentialFileLocation=$(env | grep AWS_SHARED_CREDENTIALS_FILE | cut -d= -f2);
    if [ -z $credentialFileLocation ]; then
        credentialFileLocation=~/.aws/credentials
    fi
    while read line; do
        if [[ $line == "["* ]]; then echo "$line"; fi;
    done < $credentialFileLocation;
}

function _awsListProfile() {
    profileFileLocation=$(env | grep AWS_CONFIG_FILE | cut -d= -f2);
    if [ -z $profileFileLocation ]; then
        profileFileLocation=~/.aws/config
    fi
    while read line; do
        if [[ $line == "["* ]]; then echo "$line"; fi;
    done < $profileFileLocation;
};

# Switch profile by setting all env vars
function _awsSwitchProfile() {
   if [ -z $1 ]; then  echo "Usage: awsp profilename"; return; fi
   exists="$(aws configure get aws_access_key_id --profile $1)"
   role_arn="$(aws configure get role_arn --profile $1)"
   if [[ -n $exists || -n $role_arn ]]; then
       if [[ -n $role_arn ]]; then
           mfa_serial="$(aws configure get mfa_serial --profile $1)"
           if [[ -n $mfa_serial ]]; then
               echo "Please enter your MFA token for $mfa_serial:"
               read mfa_token
           fi

           source_profile="$(aws configure get source_profile --profile $1)"
           if [[ -n $source_profile ]]; then
               profile=$source_profile
           else
               profile=$1
           fi

           echo "Assuming role $role_arn using profile $profile"
           if [[ -n $mfa_serial ]]; then
               JSON="$(aws sts assume-role --profile=$profile --role-arn $role_arn --role-session-name "$profile" --serial-number $mfa_serial --token-code $mfa_token)"
           else
               JSON="$(aws sts assume-role --profile=$profile --role-arn $role_arn --role-session-name "$profile")"
           fi

           aws_access_key_id="$(echo $JSON | jq -r '.Credentials.AccessKeyId')"
           aws_secret_access_key="$(echo $JSON | jq -r '.Credentials.SecretAccessKey')"
           aws_session_token="$(echo $JSON | jq -r '.Credentials.SessionToken')"
       else
           aws_access_key_id="$(aws configure get aws_access_key_id --profile $1)"
           aws_secret_access_key="$(aws configure get aws_secret_access_key --profile $1)"
           aws_session_token=""
       fi
       export AWS_DEFAULT_PROFILE=$1
	   export AWS_PROFILE=$1
       export AWS_ACCESS_KEY_ID=$aws_access_key_id
       export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
       [[ -z "$aws_session_token" ]] && unset AWS_SESSION_TOKEN || export AWS_SESSION_TOKEN=$aws_session_token

       echo "Switched to AWS Profile: $1";
       aws configure list
   fi
}

# Set AWS_DEFAULT_PROFILE and AWS_PROFILE env variables
function _awsSetProfile() {
   if [ -z $1 ]; then  echo "Usage: awsp profilename"; return; fi

   export AWS_DEFAULT_PROFILE=$1
   export AWS_PROFILE=$1

   echo "Switched to AWS Profile: $1"
   echo "Environment variables with credentials were not set (which is desired). Sample commands to run:"
   echo "$ aws-vault exec $1 -- aws s3 ls    <-- if this is too long"
   echo "$ aws s3 ls   <-- this is the same but shorter and using AWS profile $1"
}
