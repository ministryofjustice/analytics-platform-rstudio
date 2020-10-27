title 'Working Conda'

control 'Conda available' do
  impact 'high'
  title 'Conda installer should be available to use'
  desc 'The Conda installer is not preferred, but is the only way to install some packages.'
  tag 'installer'
  tag 'conda'

  describe command('conda info') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /conda version : 4.9.0/ }
  end
end
