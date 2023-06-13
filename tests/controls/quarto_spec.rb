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
    its('stderr') { should match /Pandoc version ([0-9\.:]+) OK/ }
    its('stderr') { should match /Dart Sass version ([0-9\.:]+) OK/ }
    its('stderr') { should match /quarto dependencies([\.]+)OK/ }
    its('stderr') { should match /Quarto installation([\.]+)OK/ }
    its('stderr') { should match /markdown render([\.]+)OK/ }
    its('stderr') { should match /Python 3 installation([\.]+)OK/ }
    its('stderr') { should match /R installation([\.]+)OK/ }
    its('exit_status') { should eq 0 }
  end
end
