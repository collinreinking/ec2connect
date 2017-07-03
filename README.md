# ec2connect
Tool for w205 students to easily start and connect to their ec2 instance

If you are using iterm (Free @ https://www.iterm2.com/) (Mac OSX)
you should place this file in ~/Library/Application\ Support/iTerm/Scripts/
Make it executable with ` chmod u+x ~/Library/Application\ Support/iTerm/Scripts/ec2.sh `


Add ` . ~/Library/Application\ Support/iTerm/Scripts/ec2.sh ` to your ~/.bash_profile

After you set up the aws stuff (instructions below), run ec2init from your terminal
to input all the information ec2connect will need.
in the future you will be able to start and connect to your ec2 by simply typing ec2.
read through the code below to see what other functions this script adds.


### Install AWS cli
Full instructions: http://docs.aws.amazon.com/cli/latest/userguide/installing.html
I had to add an export to my path file as described here: http://docs.aws.amazon.com/cli/latest/userguide/cli-install-macos.html#awscli-install-osx-path

### configure Aws cli
http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
**in order to finish this you will need to create Access keys.**
Amazon gives you instructions on the link above using the IAM console
but before I had seen that I had already created an access key using the instructions here: http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html . 

### set an elastic ip address for your instance
very easy to set up from https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Addresses
