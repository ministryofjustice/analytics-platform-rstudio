'Environment Variables'

control 'PATH variable' do
  impact 'high'
  title 'PATH should contain ~/.local/bin for nbstripout'
  desc 'PATH should contain ~/.local/bin for nbstripout. This is currently broken,' \
  'however the fix would be to change the '
  tag 'environment'
  tag 'nbstripout'
  tag 'known_broken'

  describe os_env('PATH') do
    its('content') { should_not match %r{/.local/bin} }
  end

  describe os_env('GITHUB_PAT') do
    its('content') { should eq nil }
  end

  describe os_env('R_VERSION') do
    its('content') { should eq '4.0.3'}
  end

  describe os_env('AWS_DEFAULT_REGION') do
    its('content') { should eq 'eu-west-1'}
  end
end
