title 'Working Conda'

control 'docker' do
  impact 'high'
  title 'Conda installer should be available to use'
  desc 'The Conda installer is not preferred, but is the only way to install some packages.'
  tag 'installer'
  tag 'conda'

  describe docker_container('rstudio_test_1') do
    it { should exist }
    it { should be_running }
  end

  # command('conda info') do
  #   its('exit_status') { should eq 0 }
  #   its('stdout') { should match /conda version : 4.9.0/ }
  # end
end
