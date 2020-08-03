'Environment Variables'

control 'PATH variable' do
  impact 'high'
  title 'PATH should contain ~/.local/bin for nbstripout'
  desc 'PATH should contain ~/.local/bin for nbstripout'
  tag 'environment'
  tag 'nbstripout'

  describe os_env('PATH') do
    its('content') { should match %r{.local/bin} }
  end
end
