#!/bin/bash

if [ ! -d /repo ]; then
  echo "/repo directory not present."
  exit 1
fi

cd /repo

#########################################################################
# NOTE: The following codepath will only be triggered outside of CodeShip
#########################################################################
if [[ -z "${CHEF_KEY_ENCRYPTION_KEY}" ]] && [ -f /codeship.aes ] && [ -f codeship-test/environment.encrypted ]; then
  /crypto.py decrypt --key-path /codeship.aes \
    /repo/codeship-test/environment.encrypted /tmp/environment
  set -a
  . /tmp/environment
  set +a
fi

if [ ! -e codeship-test/ssh.key.encrypted ]; then
  echo "Encrypted SSH private key not present."
  exit 1
else
  echo "Decrypting SSH private key..."
  if ! mkdir /repo/secrets; then
    echo "Failed to create /repo/secrets directory."
    exit 1
  fi

  if ! chmod 0700 /repo/secrets; then
    echo "Failed to change permissions of /repo/secrets directory."
    exit 1
  fi

  if ! openssl enc -d -aes-256-cbc -k ${AWS_SSH_KEY_ENCRYPTION_KEY} -a -in codeship-test/ssh.key.encrypted -out /repo/secrets/codeship-test; then
    echo "Failed to decrypt SSH private key."
    exit 1
  fi

  if ! chmod 0600 /repo/secrets/codeship-test; then
    echo "Failed to change permissions of SSH private key."
    exit 1
  fi
fi

if [ ! -e codeship-test/chef/codeship.pem.encrypted ]; then
  echo "Encrypted Chef private key is not present."
  exit 1
else
  echo "Decrypting Chef private key..."
  if ! openssl enc -d -aes-256-cbc -k ${CHEF_KEY_ENCRYPTION_KEY} -a -in codeship-test/chef/codeship.pem.encrypted -out /.chef/codeship.pem; then
    echo "Failed to decrypt Chef private key."
    exit 1
  fi

  if ! chmod 0600 /.chef/codeship.pem; then
    echo "Failed to set permissions on Chef private key."
    exit 1
  fi
fi

if [ ! -e codeship-test/chef/codeship-foodtruck-usw2.pem.encrypted ]; then
  echo "Encrypted foodtruck-usw2 Chef private key is not present."
  exit 1
else
  echo "Decrypting Chef private key..."
  if ! openssl enc -d -aes-256-cbc -k ${CHEF_KEY_ENCRYPTION_KEY} -a -in codeship-test/chef/codeship-foodtruck-usw2.pem.encrypted -out /.chef/codeship-foodtruck-usw2.pem; then
    echo "Failed to decrypt Chef private key."
    exit 1
  fi

  if ! chmod 0600 /.chef/codeship-foodtruck-usw2.pem; then
    echo "Failed to set permissions on Chef private key."
    exit 1
  fi
fi

# Create linkages into persisted docker volume
rm -rf .kitchen
mkdir -p /shared_state/kitchen
ln -s /shared_state/kitchen .kitchen
mkdir -p /shared_state/berkshelf
ln -s /shared_state/berkshelf ~/.berkshelf

test -f /shared_state/Berksfile.lock && cp /shared_state/Berksfile.lock Berksfile.lock

export AWS_SSH_KEY_PATH=/repo/secrets/codeship-test
export AWS_SSH_KEY_ID=codeship-test
export KITCHEN_DRIVER=ec2
export KITCHEN_EC2_HOSTNAME="test-kitchen-cs-${CI_REPO_NAME}"

# Run the passed-in command...
$*

EC=$?

test -f Berksfile.lock && cp Berksfile.lock /shared_state/Berksfile.lock

exit $EC
