#!/bin/bash

# Create a temp directory in your repository
mkdir mdapi_temp_dir
 
# Convert your sources to the metadata API format
# and place them in the temp directory
sfdx force:source:convert -d mdapi_temp_dir/
 
# Deploy the sources to a target org
# Assuming that $targetOrg is a username on the target org
# Command times out if it takes longer than 10 minutes
sfdx force:mdapi:deploy -d mdapi_temp_dir/ -u $targetOrg -w 10
 
# Remove the temp directory
rm -fr mdapi_temp_dir