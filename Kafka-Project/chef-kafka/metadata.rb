name 'kafka'
maintainer ' TLA'
maintainer_email 'infrastructure@.com'
license 'All Rights Reserved'
description 'Installs/Configures kafka'
version '0.3.28'

depends 'java'
depends 'chef-vault'
depends 'ark'
depends 'apt'
depends 'collectd'
depends 'nrpe'
depends 'users'
depends 'sudo'
depends 'ulimit'
depends 'runit'

depends 'reverse-exporter'
depends 'zookeeper'

chef_version '>= 14.0'

supports 'ubuntu', '>= 18.04'

issues_url 'https://github.com//kafka/issues'
source_url 'https://github.com//kafka'
