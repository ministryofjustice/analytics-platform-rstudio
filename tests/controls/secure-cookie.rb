control 'Secure Cookie' do
  impact 'high'
  title 'secure-cookie-key is set'
  desc 'The secure cookie should be set so that it matches the load balancer (auth-proxy) key' \
  'https://docs.rstudio.com/ide/server-pro/latest/load-balancing.html'
  tag 'rstudio'

  describe file('/var/lib/rstudio-server/secure-cookie-key') do
    its('content') { should match '8865825c306d4bd1a90c505dcde189fb' }
  end
end
