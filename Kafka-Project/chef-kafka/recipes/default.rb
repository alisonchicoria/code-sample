#
# Cookbook:: kafka
# Recipe:: default

# Upate APT Repo
apt_update 'update'

include_recipe 'java'
include_recipe 'runit'

java_home = node['java']['java_home']

user = node['kafka']['user']
group = node['kafka']['group']

if node['kafka']['broker_id'].nil? || node['kafka']['broker_id'].empty?
  node.default['kafka']['broker_id'] = node['ipaddress'].gsub('.', '')
end

if node['kafka']['broker_host_name'].nil? || node['kafka']['broker_host_name'].empty?
  node.default['kafka']['broker_host_name'] = node['fqdn']
end

# == Users

# setup kafka group
group group do
end

# setup kafka user
user user do
  comment 'Kafka user'
  gid 'kafka'
  home '/home/kafka'
  shell '/bin/noshell'
  manage_home false
end

execute 'ulimit' do
  command 'sudo -u kafka bash -c "ulimit -n 1000000"'
  user  'root'
  group 'root'
  action :run
end

# ulimit kafka user
user_ulimit 'kafka' do
  filehandle_soft_limit 500000
  filehandle_hard_limit 1100000
  process_soft_limit 'unlimited'
  process_hard_limit 'unlimited'
  memory_limit 'unlimited'
end

# create the install directory
install_dir = node['kafka']['install_dir']
data_dir = node['kafka']['data_dir']
log_dir = node['kafka']['log_dir']

directory "#{install_dir}/" do
  owner 'root'
  group 'root'
  mode '00755'
  recursive true
  action :create
end

# create the log directory
directory "#{log_dir}/" do
  owner 'kafka'
  group 'kafka'
  mode '00755'
  recursive true
  action :create
end

# create the data directory
directory "#{data_dir}/" do
  owner 'kafka'
  group 'kafka'
  mode '00755'
  recursive true
  action :create
end

directory "#{install_dir}/bin" do
  owner 'root'
  group 'root'
  mode '00755'
  recursive true
  action :create
end

directory "#{install_dir}/config" do
  owner 'root'
  group 'root'
  mode '00755'
  recursive true
  action :create
end

# pull the remote file only if we create the directory
tar_gz = [kafka_version_name, 'tgz'].join('.')
local_download_path = ::File.join(Chef::Config.file_cache_path, tar_gz)
remote_path = [node['kafka']['base_url'], node['kafka']['version'], tar_gz].join('/')

remote_file local_download_path do
  source remote_path
  mode '644'
  not_if { kafka_installed? }
end

execute 'tar' do
  user  'root'
  group 'root'
  cwd install_dir
  ## action :nothing
  command "tar zxvf #{local_download_path}"
end

execute 'movement-folder' do
  user  'root'
  group 'root'
  cwd install_dir
  ## action :nothing
  command "cp -rf #{kafka_version_name}/* ."
end

%w(server.properties log4j.properties).each do |template_file|
  template "#{install_dir}/config/#{template_file}" do
    source "#{template_file}.erb"
    owner user
    group group
    mode  '00755'
    variables(
      kafka: node['kafka']
    )
  end
end

template '/etc/hosts' do
  source 'hosts.erb'
  owner 'root'
  group 'root'
  mode  '00644'
  variables(
    kafka: node['kafka']
  )
end

template "#{java_home}/jmxremote.access" do
  source 'jmxremote.access'
  owner 'root'
  group 'root'
  mode  '00644'
  variables(
    kafka: node['kafka']
  )
end

template "#{java_home}/jmxremote.password" do
  source 'jmxremote.password'
  owner 'root'
  group 'root'
  mode  '00600'
  variables(
    kafka: node['kafka']
  )
end

template "#{install_dir}/bin/service-control" do
  source 'service-control.erb'
  owner 'root'
  group 'root'
  mode  '00755'
  variables(
  install_dir: install_dir,
  log_dir: node['kafka']['log_dir'],
  java_home: java_home,
  java_jmx_port: node['kafka']['jmx_port'],
  java_class: 'kafka.Kafka',
  user: user
)
end

template '/etc/systemd/system/kafka.service' do
  source 'kafka.service'
  owner 'root'
  group 'root'
  mode  '00644'
  variables(
    kafka: node['kafka']
  )
end

execute 'cleanup' do
  command 'rm /opt/kafka/bin/kafka-server-start.sh'
  action :run
end

template '/opt/kafka/bin/kafka-server-start.sh' do
  source 'kafka-server-start.erb'
  owner 'root'
  group 'root'
  mode  '00755'
  variables(
    kafka: node['kafka']
  )
end

# fix perms and ownership
execute 'chmod' do
  command "find #{install_dir} -name bin -prune -o -type f -exec chmod 644 {} \\; && find #{install_dir} -type d -exec chmod 755 {} \\;"
  action :run
end

execute 'chown' do
  command "chown -R root:root #{install_dir}"
  action :run
end

execute 'chmod' do
  command "chmod -R 755 #{install_dir}/bin"
  action :run
end

execute 'chown' do
  command "chown -R kafka:kafka #{java_home}/jmxremote.password"
  action :run
end

execute 'chmod' do
  command "chmod -R 600 #{java_home}/jmxremote.password"
  action :run
end

# create collectd plugin for kafka JMX objects if collectd has been applied.
if node.attribute?('collectd')
  template "#{node['collectd']['plugin_conf_dir']}/collectd_kafka-broker.conf" do
    source 'collectd_kafka-broker.conf.erb'
    owner 'root'
    group 'root'
    mode '00644'
    notifies :restart, 'service:[collectd]'
  end
end

# Setup Zookeeper
include_recipe 'zookeeper::default'

# Recipe Prometheus
include_recipe 'kafka::prometheus'

# Search for Zookeeper peer nodes
kafka_nodes = search(:node, "#{node['kafka']['search_query']} AND chef_environment:#{node.chef_environment} AND zookeeper_zookeeper_application:#{node['kafka']['application']}")
kafka_nodes << node unless kafka_nodes.find { |kafka_node| kafka_node['ipaddress'].include?(node['ipaddress']) }

# command 'cd /opt/kafka/bin/ && ./service-control start &'
execute 'kafka-service' do
  command 'systemctl start kafka.service'
  user  'root'
  group 'root'
  action :run
end

execute 'burrow' do
  command 'cd /opt/metrics/burrow/ && ./burrow &'
  user  'root'
  group 'root'
  action :run
end

execute 'kminion_env' do
  command 'export CONFIG_FILEPATH=/opt/metrics/minion/kminion.yaml'
  user  'root'
  group 'root'
  action :run
end

execute 'kminion' do
  command 'cd /opt/metrics/minion/ && ./kminion &'
  user  'root'
  group 'root'
  action :run
end

execute 'kafkactl' do
  command 'wget https://github.com/deviceinsight/kafkactl/releases/download/v2.2.0/kafkactl_2.2.0_linux_amd64.deb && dpkg -i kafkactl_2.2.0_linux_amd64.deb'
  user  'root'
  group 'root'
  action :run
end
