#!/bin/bash

# AWS
apt-get update
apt-get install -y awscli net-tools jq


# Mount EBS volume
sudo mkfs -t xfs /dev/nvme1n1
sudo mkdir -p /var/lib/mongodb
sudo mount /dev/nvme1n1 /var/lib/mongodb

BLK_ID=$(sudo blkid /dev/nvme1n1 | cut -f2 -d" ")
if [[ -z $BLK_ID ]]; then
  echo "Hmm ... no block ID found ... "
  exit 1
fi

echo "$BLK_ID     /var/lib/mongodb   xfs    defaults   0   2" | sudo tee --append /etc/fstab

sudo mount -a

# Populate IP Address for the Nodes

mongo0="$(aws ec2 describe-instances --filters "Name=tag:Role,Values=primary" "Name=instance-state-name,Values=running" --region ${aws_region} | jq .Reservations[0].Instances[0].PrivateIpAddress --raw-output)"
mongo1="$(aws ec2 describe-instances --filters "Name=tag:Role,Values=secondary" "Name=instance-state-name,Values=running" --region ${aws_region} | jq .Reservations[0].Instances[0].PrivateIpAddress --raw-output)"

#ownid="$(curl http://169.254.169.254/latest/meta-data/instance-id)"
#replset=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$ownid" --region ${aws_region} | jq -r '.Tags[] | select(.Key=="Replset").Value')

private_ip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)


# MONGO

# Make sure you have installed the gnupg package
sudo apt-get install gnupg -y
# Import the MongoDB public GPG Key
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
#2. Create a list file for MongoDB repository
# Create the /etc/apt/sources.list.d/mongodb-org-4.4.list file for Ubuntu
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -sc)/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
# Then make sure the local package database reloaded
sudo apt-get update
#3. Install MongoDB
# Install the latest stable package
sudo apt-get install -y mongodb-org

sudo chown mongodb:mongodb -R /var/lib/mongodb

#4. Run MongoDB
# Start the process on systemd init
sudo systemctl start mongod
#5. MongoDB is up and running !

# Enable Autostart the process
sudo systemctl enable mongod
# Restart the process
sudo systemctl restart mongod

sleep 10

# set config file
sed -i "s/127.0.0.1/127.0.0.1,$private_ip/g" /etc/mongod.conf

#Create KeyFile Authentication
echo "9XXBIyqpYiattfaSweGc7re07ozCG0WU2liypRkLTXSWrUtUJ7k0OYRnEJEKkksJ
ElPMrKV5jr3Joe/D2u/mwIk8qO0dTKtcXbJ1kEq5XFadMBXHe4Ulfj6hgcM58p7x
edYCZPJPSKCqCmYWw/TKgWDgW2hiHhwTyKr2udifQwlsrHhUjpi8vxKQGXOX08Jr
U0X4O6pBHMimmrstbiFleeUq/Wqng8ZROH/U3ZZC4J0yzX/DieTdShMEq4e/PWxd
4S0AHKx/I6fvMxX3i3BRLbMDkopodRVBkwCGqYje+nAcP6RzzNX7p1g0NnKkgt/p
NL3HQs7co5lrf7E2bX+YEp0p4PNj5Y8NAROGN7wdrQr3E1eWCVmLoGRruMVKl+MY
2bDYFcKiB7jBTwd9Ny/gSEFZa2qdmVpM+Qm9Y/HqeMs1ek9PBT03ajZcTE3ZVQt5
d6WcPcwYrXQQxYst787jZFUascRcWVSXSgvb8S9Al4lBqe3FvkOGgWq67zR5uHMY
OPSvzB3e145B2Ft3koBeDRK5yyJvzDBAVB0MBvbyXCuGftRwCs1gsQA5Fcm16Hxc
WUXde7HcFTJuenCoab8MkRYB4kr4YBHf7zsx8oyB2C0AjGq7NkP9jigryXZqV3iR
zPzzLDEUMrdMeC432uMlmGaKk744YdvNToqU4ysTtEFang/EC3Fca6bxUZTssna5
0j3JHRb85gOtj8YudwqCNTdDaayteWXkT4455DJvcx0k1xdcBK6xW9XJu35jXCcv
njjwJgvP611LFMT+uMXDWXAOYyioAg3CfNNFBjCn3XQrfwwt+y2mXDTS/7D8nMII
MJl1Ke35i7Z2LwWzsyB0syB99YCocRAXhHXwot9vcDK9SXpsY6Y4DCq0/0Uvjpk3
mcUObRDs0g0pnWx+3Ja697E9Z0trynaTHC5K5KnOE+5S/bh+k0piMKz+5AFNPlBF
h9VwQKxSe9UECC0Ai1Np4GF+lYpzO3Og7x6v7IeRSb+5rQME" > /etc/KeyFile
chown mongodb /etc/KeyFile
chmod 600 /etc/KeyFile


#  Create Admin User
mongo <<EOF
use admin
db.createUser({
  user: "admin",
  pwd: "${mongo_admin_password}",
  roles: [ { role: "root", db: "admin" } ]
})
EOF

#  Create User for Authentication
mongo <<EOF
use admin
db.createUser({
  user: "${mongo_user}",
  pwd: "${mongo_password}",
  roles: [
    { role: "dbOwner", db: "${mongo_database}" }
  ]
})
EOF

echo "replication:" >> /etc/mongod.conf
echo "    replSetName: 'rs0'" >> /etc/mongod.conf

echo "security:" >> /etc/mongod.conf
echo "    keyFile: /etc/KeyFile" >> /etc/mongod.conf
echo "    authorization: enabled" >> /etc/mongod.conf

sudo systemctl restart mongod

sudo systemctl status mongod

netstat -atunp | grep mongo

# Wait for the mongodb startup
sleep 10

# Initialize replica set
mongo mongodb://admin:${mongo_admin_password}@localhost --eval 'rs.initiate({ "_id": "rs0", "members": [ { "_id": 0, "host": "'"$mongo0"':27017" }, { "_id": 1, "host": "'"$mongo1"':27017" } ] })'
