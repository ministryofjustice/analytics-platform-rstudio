title 'RStudio User'

control 'Common Users' do
  impact 'high'
  title 'The rstudio user should exist'
  desc 'The rstudio user should exist This makes sure that it has the same UID & GID as the jupyter images'
  tag 'user'
  tag 'group'

  describe user('rstudio') do
    it { should exist }
    its('uid') { should eq 1000 }
  end
end

control 'Common Groups' do
  impact 'high'
  title 'The rstudio user should have the corect groups'
  desc 'rstudio should have the primary group of users and also be in the staff group to match RStudio, but not break this image'

  describe user('rstudio') do
    its('gid') { should eq 1000 }
    # its('groups') { should eq ['rstudio','staff', 'users']}
  end
end
