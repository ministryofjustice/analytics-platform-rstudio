control 'R Version' do
  impact 'high'
  title 'A recent R Version'
  desc 'We should have a recent version of R so that RStudio users can use the latest' \
  'patched packages'
  tag 'environment'
  tag 'r'

  describe command('r --version') do
    its('stdout') { should match /GNU R Version 4.0./ }
  end
end
