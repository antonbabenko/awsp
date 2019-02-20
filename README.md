# AWS credential profile changer

Excerpt from [IAM Best Practices](http://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#delegate-using-roles):

> **Delegate by using roles instead of by sharing credentials**
    
> You might need to allow users from another AWS account to access resources in your AWS account. If so, don't share security credentials, such as access keys, between accounts. Instead, use IAM roles. You can define a role that specifies what permissions the IAM users in the other account are allowed, and from which AWS accounts the IAM users are allowed to assume the role.

To make process of switching profiles (environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` among others) it is handy to use the code provided on this repo.

Features
========

* Autocomplete of available profiles (`awsp + tab + tab`)
* Support configurable location of credentials file (`AWS_SHARED_CREDENTIALS_FILE` environment variable)
* Full compatibility with official AWS CLI
* Assume roles which require MFA
* Integration with [aws-vault](https://github.com/99designs/aws-vault) to prevent secrets from storing in plain-text

Install
=======

* [jq](https://stedolan.github.io/jq/) should be installed
* Download [awsp_functions.sh](https://raw.githubusercontent.com/antonbabenko/awsp/master/awsp_functions.sh) anywhere you like (for example, `~/awsp_functions.sh`) and make it executable:

```
    $ wget -O ~/awsp_functions.sh https://raw.githubusercontent.com/antonbabenko/awsp/master/awsp_functions.sh
    $ chmod +x ~/awsp_functions.sh
   ```
   
* Depending on which version of shell you use, edit `~/.bash_profile` or similar to include: `source ~/awsp_functions.sh`
* (Optional) Enable aliases and auto-completion into your `~/.bash_profile` or similar:

```
    alias awsall="_awsConfigListAll"
    alias awsp="_awsSetProfile"
    alias awswho="aws configure list"

    complete -W "$(cat $HOME/.aws/credentials | grep -Eo '\[.*\]' | tr -d '[]')" _awsSwitchProfile
    complete -W "$(cat $HOME/.aws/config | grep -Eo '\[.*\]' | tr -d '[]' | cut -d " " -f 2)" _awsSetProfile
```

Examples
========

Content of `~/.aws/config`:
```
[company-anton]
aws_access_key_id=EXAMPLEACCESSKEY
aws_secret_access_key=EXAMPLESECRETACCESSKEY

[company-staging-anton]
role_arn=arn:aws:iam::222222222222:role/company-staging
source_profile=company-anton

[company-production-anton]
role_arn=arn:aws:iam::111111111111:role/company-production
source_profile=company-anton
mfa_serial=arn:aws:iam::333333333333:mfa/anton
```

To change AWS profile to use staging account (222222222222):

    $ awsp company-staging-anton
    
To change AWS profile to use production account (111111111111) which requires MFA token created in IAM account (333333333333, `company-anton`):

    $ awsp company-production-anton
    # Please enter your MFA token for arn:aws:iam::333333333333:mfa/anton
    > 123456
    
Notes
=====

1. This code has been tested only on Mac and there are no intentions to make it to work on other systems (if necessary)!

1. To avoid storing AWS secrets in plain text you can use [aws-vault](https://github.com/99designs/aws-vault), while keeping the same `awsp` script to switch roles.

Authors
=======

Created by [Anton Babenko](https://github.com/antonbabenko) with inspiration from [several](https://github.com/antonosmond/bash_profile/blob/master/.bash_profile) [code snippets](http://www.jayway.com/2015/09/25/aws-cli-profile-management-made-easy/)

License
=======

Apache 2 Licensed. See LICENSE for full details.
