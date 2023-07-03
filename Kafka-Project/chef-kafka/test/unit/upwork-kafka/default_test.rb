describe command('true') do
  its('exit_status') { should eq 0 }
end
