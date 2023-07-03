describe command('true') do
  its('exit_status') { should eq 0 }
end

describe systemd_service('reverse_exporter') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe systemd_service('node_exporter_main') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end
