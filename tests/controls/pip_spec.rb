title 'Working Pip'

control 'Pip available' do
  impact 'high'
  title 'Pip should be available to use'
  desc 'Pip is the preferred installer for python packages.'
  tag 'installer'
  tag 'pip'
  tag 'version'

  describe command('pip  --version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /pip 20/ }
  end
end
