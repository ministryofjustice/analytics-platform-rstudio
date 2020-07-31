title 'Python Libraries'

control 'Pandas can read a CSV' do
  impact 'high'
  title 'Python Pandas is installed and can read a CSV'
  desc 'Python Pandas is installed and can read a CSV'
  tag 'python'

  describe command('python /tests/pandas_read_csv.py') do
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

  describe command('python /tests/pandas_read_s3.py') do
    its('stdout') { should_not match /foo bar baz/ }
    its('exit_status') { should_not eq 0 }
  end
end
