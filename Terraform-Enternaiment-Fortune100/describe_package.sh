#!/bin/bash

aws es describe-packages --filters "Name=PackageName,Value=$1" | jq -r ".PackageDetailsList[0].PackageID"
