#
# Cookbook:: kafka
# Libraries:: helpers
#

def kafka_version_name
  %(kafka_#{node['kafka']['scala_version']}-#{node['kafka']['version']})
end

def kafka_jar_path
  ::File.join(node['kafka']['install_dir'], 'libs', %(#{kafka_version_name}.jar))
end

def kafka_installed?
  ::File.exist?(node['kafka']['install_dir']) && ::File.exist?(kafka_jar_path)
end

def kafka_init_style
  (style = node['kafka']['init_style']) && style.to_sym
end

def kafka_init_opts
  @kafka_init_opts ||= {}.tap do |opts|
    case kafka_init_style
    when :sysv
      opts[:env_path] = value_for_platform_family(
        'debian' => '/etc/default/kafka',
        'default' => '/etc/sysconfig/kafka'
      )
      opts[:source] = value_for_platform_family(
        'debian' => 'sysv/debian.erb',
        'default' => 'sysv/default.erb'
      )
      opts[:script_path] = '/etc/init.d/kafka'
      opts[:permissions] = '755'
    when :upstart
      opts[:env_path] = '/etc/default/kafka'
      opts[:source] = value_for_platform_family(
        'default' => 'upstart/default.erb'
      )
      opts[:script_path] = '/etc/init/kafka.conf'
      opts[:provider] = ::Chef::Provider::Service::Upstart
      opts[:permissions] = '644'
    when :systemd
      opts[:env_path] = value_for_platform_family(
        'debian' => '/etc/default/kafka',
        'default' => '/etc/sysconfig/kafka'
      )
      opts[:source] = value_for_platform_family(
        'default' => 'systemd/default.erb'
      )
      opts[:script_path] = '/etc/systemd/system/kafka.service'
      opts[:provider] = ::Chef::Provider::Service::Systemd
      opts[:permissions] = '644'
    end
  end
end

def start_automatically?
  !!node['kafka']['automatic_start'] || restart_on_configuration_change?
end

def restart_on_configuration_change?
  !!node['kafka']['automatic_restart']
end

def kafka_service_actions
  actions = [:enable]
  actions << :start if start_automatically?
  actions
end

def kafka_log_dirs
  Array(node['kafka']['broker']['log.dirs'])
end

def fetch_broker_attribute(*parts)
  node['kafka']['broker'][parts.map(&:to_s).join('.')]
end

def kafka_service_resource
  kafka_runit? ? 'runit_service[kafka]' : 'service[kafka]'
end

def kafka_runit?
  kafka_init_style == :runit
end

def kafka_systemd?
  kafka_init_style == :systemd
end

def kafka_env
  Kafka::Env.new(node['kafka'].to_hash)
end
