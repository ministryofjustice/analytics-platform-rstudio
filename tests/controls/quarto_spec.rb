title 'Quarto check'

control 'Quarto available' do
  impact 'high'
  title 'Quarto should be available to use'
  desc 'Quarto is .'
  tag 'tool'
  tag 'quarto'
  tag 'version'

  describe command('quarto  --version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /1.3/ }
  end
end

control 'Quarto check' do
  impact 'high'
  title 'Quarto installation check'
  desc 'Check the status of quarto'
  tag 'quarto'

  describe command('quarto check') do
    its('stdout') { should match /Pandoc OK/ }
    its('stdout') { should match /Dart Sass OK/ }
    its('stdout') { should match /quarto dependencies OK/ }
    its('stdout') { should match /Quarto installation OK/ }
    its('stdout') { should match /markdown render OK/ }
    its('stdout') { should match /Python 3 installation OK/ }
    its('stdout') { should match /R installation OK/ }
    its('stdout') { should eq '' }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end
end
