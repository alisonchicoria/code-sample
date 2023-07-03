#!/bin/bash
BUCKET=chef-ci-cache-szqwzmn7o1ad

if [ x$1 == 'xdownload' ]; then
  if aws s3 ls s3://${BUCKET}/cache.tar.gz; then
    (cd /shared_state/berkshelf/ ; aws s3 cp s3://${BUCKET}/cache.tar.gz - | tar -xz)
  else
    echo "cache tarball doesnt exist, skipping download"
  fi
elif [ x$1 == 'xupload' ]; then
  (cd /shared_state/berkshelf/ ; tar cz . | aws s3 cp - s3://${BUCKET}/cache.tar.gz)
else
  echo must have an argument of download or upload
  exit 1
fi
