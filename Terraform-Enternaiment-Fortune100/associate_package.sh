#!/bin/bash

package_id=$(aws es describe-packages --filters "Name=PackageName,Value=$1" | jq -r ".PackageDetailsList[0].PackageID")
aws es associate-package --package-id "$package_id" --domain-name "$2"