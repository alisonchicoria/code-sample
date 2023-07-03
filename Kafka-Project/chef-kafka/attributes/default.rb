#
# Cookbook:: kafka
# Attributes:: default
#

#
# Version of Kafka to install.
default['kafka']['version'] = '3.2.0'

# Zookeeper Configuration
override['zookeeper']['search_query'] = 'recipe:kafka'

#
# Base URL for Kafka releases. The recipes will a download URL using the
# `base_url`, `version` and `scala_version` attributes.
default['kafka']['base_url'] = 'https://archive.apache.org/dist/kafka/'

#
# SHA-256 checksum of the archive to download, used by Chef's `remote_file`
# resource.
default['kafka']['checksum'] = '93b6f926b10b3ba826266272e3bd9d0fe8b33046da9a2688c58d403eb0a43430'

#
# MD5 checksum of the archive to download, which will be used to validate that
# the "correct" archive has been downloaded.
default['kafka']['md5_checksum'] = nil

#
# SHA512 checksum of the archive to download, which will be used to validate that
# the "correct" archive has been downloaded.
default['kafka']['sha512_checksum'] = '2bf14a07c569c84736271471a9abb7b937b311780ed2a3d969ac0123737319e9151e0a69d6b8bd309a57b92cb00a90400e8e19e0512a6ee9206b2c91826af930'

#
# Scala version of Kafka.
default['kafka']['scala_version'] = '2.13'

#
# Directory where to install Kafka.
default['kafka']['install_dir'] = '/opt/kafka'

#
# Directory where to install *this* version of Kafka.
# For actual default value see `_defaults` recipe.
default['kafka']['version_install_dir'] = nil

#
# Directory where the downloaded archive will be extracted to.
default['kafka']['build_dir'] = '/tmp/kitchen/cache/'

#
# Directory where store Data from Kafka Cluster
default['kafka']['data_dir'] = '/data/kafka'

#
# Directory where to store logs from Kafka.
default['kafka']['log_dir'] = '/data/log/kafka'

default['kafka'][:chroot_suffix] = 'brokers'

#
# Directory where to keep Kafka configuration files. For the
# actual default value see `_defaults` recipe.
default['kafka']['config_dir'] = '/opt/kafka/config/'

#
# Kafka Settings
default['kafka']['num_partitions'] = 200
default['kafka']['broker_id'] = nil
default['kafka']['broker_host_name'] = nil
default['kafka']['port'] = 9092
default['kafka']['ulimit_file'] = 1000000
default['kafka']['kill_timeout'] = 10
default['kafka']['threads'] = nil
default['kafka']['log_flush_interval'] = 10000
default['kafka']['log_flush_time_interval'] = 1000
default['kafka']['log_flush_scheduler_time_interval'] = 1000
default['kafka']['log_retention_hours'] = 168
default['kafka']['log.retention.bytes'] = 1099511627776
default['kafka']['zk_connectiontimeout'] = 10000

#
# JMX port for Kafka.
default['kafka']['jmx_port'] = 9999

#
# JMX configuration options for Kafka.
default['kafka']['jmx_opts'] = %w(
  -Dcom.sun.management.jmxremote
  -Dcom.sun.management.jmxremote.authenticate=false
  -Dcom.sun.management.jmxremote.ssl=false
).join(' ')

#
# User for directories, configuration files and running Kafka.
default['kafka']['user'] = 'kafka'

#
# Should node['kafka']['user'] and node['kafka']['group'] be created?
default['kafka']['manage_user'] = true

#
# Override ID for user used for directories, configuration files and running Kafka.
default['kafka']['uid'] = nil

#
# Group for directories, configuration files and running Kafka.
default['kafka']['group'] = 'kafka'

#
# Override ID for group used for directories, configuration files and running Kafka.
default['kafka']['gid'] = nil

#
# JVM heap options for Kafka.
default['kafka']['heap_opts'] = '-Xmx1G -Xms1G'

#
# Generic JVM options for Kafka.
default['kafka']['generic_opts'] = nil

#
# GC log options for Kafka. For the actual default value
# see `_defaults` recipe.
default['kafka']['gc_log_opts'] = nil

#
# Log4j options for Kafka.
default['kafka']['log4j_opts'] = lazy { format('-Dlog4j.configuration=file:%s', ::File.join(node['kafka']['config_dir'], 'log4j.properties')) }

#
# JVM Performance options for Kafka.
default['kafka']['jvm_performance_opts'] = %w(
  -server
  -XX:+UseCompressedOops
  -XX:+UseParNewGC
  -XX:+UseConcMarkSweepGC
  -XX:+CMSClassUnloadingEnabled
  -XX:+CMSScavengeBeforeRemark
  -XX:+DisableExplicitGC
  -Djava.awt.headless=true
).join(' ')

#
# The type of "init" system to install scripts for. Valid values are currently
# :sysv, :systemd and :upstart.
default['kafka']['init_style'] = :sysv

#
# The ulimit file limit.
# If this value is not set, Kafka will use whatever the system default is.
# Depending on your system setup you might want to set this to a rather high
# value, or you will most likely run into issues with Kafka simply dying for no
# particular reason as it needs to keep a lot of file handles for socket
# connections and log files for all partitions.
default['kafka']['ulimit_file'] = nil

#
# Automatically start kafka service.
default['kafka']['automatic_start'] = false

#
# Automatically restart kafka on configuration change.
# This also implies `automatic_start` even if it's set to `false`.
# The reason for this is that I can see the need for automatically starting
# Kafka if it's not running, but not necessarily restart on configuration
# changes.
default['kafka']['automatic_restart'] = false

#
# Attribute to set the recipe to used to coordinate Kafka service start
# if nothing is set the default recipe "_coordinate" will be used
# Refer to issue #58 for details.
default['kafka']['start_coordination']['recipe'] = 'kafka::_coordinate'

#
# Attribute to set the timeout in seconds when stopping the broker
# before sending SIGKILL (or equivalent).
default['kafka']['kill_timeout'] = 10

#
# `broker` namespace for configuration of a broker.
# Initially set to an empty Hash to avoid having `fetch(:broker, {})`
# statements in helper methods and the alike.
default['kafka']['broker'] = {}

#
# Root logger level and appender.
default['kafka']['log4j']['root_logger'] = 'ERROR, kafkaAppender'

#
# Appender definitions for various Kafka classes.
default['kafka']['log4j']['appenders'] = {
  'kafkaAppender' => {
    type: 'org.apache.log4j.DailyRollingFileAppender',
    date_pattern: '.yyyy-MM-dd',
    file: lazy { ::File.join(node['kafka']['log_dir'], 'kafka.log') },
    layout: {
      type: 'org.apache.log4j.PatternLayout',
      conversion_pattern: '[%d] %p %m (%c)%n',
    },
  },
  'stateChangeAppender' => {
    type: 'org.apache.log4j.DailyRollingFileAppender',
    date_pattern: '.yyyy-MM-dd',
    file: lazy { ::File.join(node['kafka']['log_dir'], 'kafka-state-change.log') },
    layout: {
      type: 'org.apache.log4j.PatternLayout',
      conversion_pattern: '[%d] %p %m (%c)%n',
    },
  },
  'requestAppender' => {
    type: 'org.apache.log4j.DailyRollingFileAppender',
    date_pattern: '.yyyy-MM-dd',
    file: lazy { ::File.join(node['kafka']['log_dir'], 'kafka-request.log') },
    layout: {
      type: 'org.apache.log4j.PatternLayout',
      conversion_pattern: '[%d] %p %m (%c)%n',
    },
  },
  'controllerAppender' => {
    type: 'org.apache.log4j.DailyRollingFileAppender',
    date_pattern: '.yyyy-MM-dd',
    file: lazy { ::File.join(node['kafka']['log_dir'], 'kafka-controller.log') },
    layout: {
      type: 'org.apache.log4j.PatternLayout',
      conversion_pattern: '[%d] %p %m (%c)%n',
    },
  },
}

#
# Logger definitions.
default['kafka']['log4j']['loggers'] = {
  'org.IOItec.zkclient.ZkClient' => {
    level: 'INFO',
  },
  'kafka.network.RequestChannel$' => {
    level: 'WARN',
    appender: 'requestAppender',
    additivity: false,
  },
  'kafka.request.logger' => {
    level: 'WARN',
    appender: 'requestAppender',
    additivity: false,
  },
  'kafka.controller' => {
    level: 'INFO',
    appender: 'controllerAppender',
    additivity: false,
  },
  'state.change.logger' => {
    level: 'INFO',
    appender: 'stateChangeAppender',
    additivity: false,
  },
}

# Search for Zookeeper peer nodes
default['kafka']['search_query'] = 'recipes:zookeeper\\:\\:default'
default['kafka']['application'] = 'test' # This will be set by Terraform
default['kafka']['clustername'] = 'test' # This will be set by Terraform
default['kafka']['id'] = '1' # This will be set by Terraform
default['kafka']['role'] = 'none' # This will be set by Terraform

# Prometheus definitions.
default['kafka']['prometheus_dir'] = '/opt/metrics'
default['kafka']['burrow']['download'] = 'https://github.com/linkedin/Burrow/releases/download/v1.4.0/Burrow_1.4.0_linux_amd64.tar.gz'
default['kafka']['burrow']['tar'] = 'Burrow_1.4.0_linux_amd64.tar.gz'
default['kafka']['minion']['download'] = 'https://github.com/cloudhut/kminion/releases/download/v2.2.0/kminion_2.2.0_linux_amd64.tar.gz'
default['kafka']['minion']['tar'] = 'kminion_2.2.0_linux_amd64.tar.gz'
default['kafka']['reverse_exporter']['download'] = 'https://github.com/wrouesnel/reverse_exporter/releases/download/v0.0.1/reverse_exporter_v0.0.1_linux-amd64.tar.gz'
default['kafka']['reverse_exporter']['tar'] = 'reverse_exporter_v0.0.1_linux-amd64.tar.gz'
default['kafka']['jmx_exporter']['download'] = 'https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.16.1/jmx_prometheus_javaagent-0.16.1.jar'
