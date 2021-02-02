title 'RStudio User'

control 'Common Users' do
  impact 'high'
  title 'The rstudio user should exist'
  desc 'The default rstudio user should be 1000'
  tag 'user'
  tag 'group'

  describe user('rstudio') do
    it { should exist }
    its('uid') { should eq 1000 }
  end

  describe user(1001) do
    it { should_not exist}
  end
end

control 'Common Groups' do
  impact 'high'
  title 'The rstudio user should have the correct groups'
  desc 'The rstudio user should have the group staff group to match Jupyter Notebook' \
  'The users group is not currently added but it should, to match Jupyter.'

  describe user('rstudio') do
    its('gid') { should eq 1000 }
    its('groups') { should eq ['rstudio','staff']}
  end
end
