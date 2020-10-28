title 'Python & Libraries'

control 'Python version' do
  impact 'high'
  title 'Python should be a specific version'
  desc 'Python should be a specific version'
  tag 'python'
  tag 'version'

  describe command('python --version') do
    its('stdout') { should match /Python 3.7/ }
    its('exit_status') { should eq 0 }
  end
end

control 'Pandas can read a CSV' do
  impact 'high'
  title 'Python Pandas is installed and can read a CSV'
  desc 'Reading from a CSV is a common task'
  tag 'python'
  only_if { ::File.exist?('/share/tests/files/pandas_read_csv.py') }

  describe command('python /share/tests/files/pandas_read_csv.py') do
    its('stdout') { should match /foo bar baz/ }
    its('exit_status') { should eq 0 }
  end
end

control 'Pandas can read a CSV from S3' do
  impact 'high'
  title 'Python Pandas is installed and can read a CSV from s3'
  desc 'Python Pandas is installed and can read a CSV from s3'
  tag 'python'
  tag 'known_broken'
  only_if { ::File.exist?('/share/tests/files/pandas_read_s3.py')}

  describe command('python /share/tests/files/pandas_read_s3.py') do
    its('stdout') { should_not match /foo bar baz/ }
    its('exit_status') { should_not eq 0 }
  end
end
