#
# Cookbook:: kafka
# Recipe:: prometheus

prometheus_dir = node['kafka']['prometheus_dir']

# create the Burrow directory
directory "#{prometheus_dir}/burrow" do
  owner 'root'
  group 'root'
  mode '00755'
  recursive true
  action :create
end

# create the minion directory
directory "#{prometheus_dir}/minion" do
  owner 'root'
  group 'root'
  mode '00755'
  recursive true
  action :create
end

# create the mjmx exporter directory
directory "#{prometheus_dir}/jmx_exporter" do
  owner 'root'
  group 'root'
  mode '00755'
  recursive true
  action :create
end

burrow_tar = node['kafka']['burrow']['tar']

# Download TAR Burrow
remote_file "#{prometheus_dir}/burrow/#{burrow_tar}" do
  source node['kafka']['burrow']['download']
  mode '644'
end

# Extract TAR Burrow
execute 'tar-burrow' do
  user  'root'
  group 'root'
  cwd "#{prometheus_dir}/burrow"
  ## action :nothing
  command "tar zxvf #{burrow_tar}"
end

# Burrow Configuration File
template "#{prometheus_dir}/burrow/burrow.toml" do
  source 'burrow.toml'
  owner 'root'
  group 'root'
  mode  '00644'
  variables(
    kafka: node['kafka']
  )
end

minion_tar = node['kafka']['minion']['tar']

# Download TAR Minion
remote_file "#{prometheus_dir}/minion/#{minion_tar}" do
  source node['kafka']['minion']['download']
  mode '644'
end

# Extract TAR Minion
execute 'tar-minion' do
  user  'root'
  group 'root'
  cwd "#{prometheus_dir}/minion"
  ## action :nothing
  command "tar zxvf #{minion_tar}"
end

# Minion Configuration File
template "#{prometheus_dir}/minion/kminion.yaml" do
  source 'kminion.yaml'
  owner 'root'
  group 'root'
  mode  '00644'
  variables(
    kafka: node['kafka']
  )
end

# Download TAR JMX Exporter
remote_file "#{prometheus_dir}/jmx_exporter/jmx_prometheus_javaagent-0.16.1.jar" do
  source node['kafka']['jmx_exporter']['download']
  mode '644'
end

# Prometheus JMX File
template "#{prometheus_dir}/jmx_exporter/jmx.yml" do
  source 'jmx.yml'
  owner 'root'
  group 'root'
  mode  '00644'
  variables(
    kafka: node['kafka']
  )
end

# Prometheus JMX File
template "#{prometheus_dir}/jmx_exporter/kafka-2_0_0.yml" do
  source 'kafka-2_0_0.yml'
  owner 'root'
  group 'root'
  mode  '00644'
  variables(
    kafka: node['kafka']
  )
end

include_recipe 'reverse-exporter::default'

include_recipe 'reverse-exporter::default_exporters'

reverse_exporter_endpoint 'burrow' do
  port 8000
  timeout '1s'
  labels(
    clustername: node['kafka']['clustername'],
    role: node['kafka']['role']
  )
end

reverse_exporter_endpoint 'kminio' do
  port 8001
  timeout '10s'
  labels(
    clustername: node['kafka']['clustername'],
    role: node['kafka']['role']
  )
end

reverse_exporter_endpoint 'kafka' do
  port 7070
  timeout '10s'
  labels(
    clustername: node['kafka']['clustername'],
    role: node['kafka']['role']
  )
end
