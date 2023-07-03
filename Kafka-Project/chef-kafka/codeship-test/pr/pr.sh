#!/bin/bash
export CI_COMMIT_MESSAGE=`git log -1 --pretty=%B`

if [ ! -e codeship-test/pr/jiracreds.encrypted ]; then
  echo "Encrypted jiracreds private key is not present."
  exit 1
else
  echo "Decrypting jiracreds private key..."
  if ! openssl enc -d -aes-256-cbc -k ${CHEF_KEY_ENCRYPTION_KEY} -a -in codeship-test/pr/jiracreds.encrypted -out codeship-test/pr/jiracreds.dencrypted; then
    echo "Failed to decrypt jiracreds private key."
    exit 1
  fi
 fi

echo "Exporting jira credentials "
source codeship-test/pr/jiracreds.dencrypted
export jira_user jira_password

pip install -r codeship-test/pr/requirements.txt
python codeship-test/pr/pr.py