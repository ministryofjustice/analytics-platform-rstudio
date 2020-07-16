title 'Working Pip'

control 'Pip available' do
  impact 1
  title 'Pip should be available to use'
  desc 'Pip is the preferred installer for python packages.'
  tag 'installer'
  tag 'pip'

  describe command('pip  --version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /pip 20/ }
  end
end
