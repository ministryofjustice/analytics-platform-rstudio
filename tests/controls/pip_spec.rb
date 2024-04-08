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
    its('stdout') { should match /pip 22/ }
  end
end

control 'osmnx' do
  impact 'high'
  title 'Install osmnx'
  desc 'Data scientists should be able top use osmnx' \
  ' OSMX is often installed, but difficult to install with system pacakges' \
  ' and rtree needing installing, which often break without lots of debugging.'
  tag 'installer'
  tag 'pip'

  describe command('pip install osmnx') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /Successfully installed/ }
  end
end
