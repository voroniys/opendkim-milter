# # encoding: utf-8

# Inspec test for recipe opendkim-milter::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe systemd_service('opendkim.service') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end
describe package('opendkim') do
  it { should be_installed }
end
describe user('opendkim') do
  it { should exist }
  its('group') { should eq 'opendkim' }
end
describe group('opendkim') do
  it { should exist }
end
describe directory('/etc/opendkim') do
  it { should exist }
  its('mode') { should cmp '00750' }
  its('owner') { should eq 'opendkim' }
  its('group') { should eq 'opendkim' }
end
describe directory('/var/run/opendkim') do
  it { should exist }
  its('mode') { should cmp '00750' }
  its('owner') { should eq 'opendkim' }
  its('group') { should eq 'opendkim' }
end
describe file('/etc/opendkim/opendkim.conf') do
  it { should be_file }
  its('mode') { should cmp '00640' }
  its('owner') { should eq 'opendkim' }
  its('content') { should match 'opendkim.sock' }
end
describe file('/etc/opendkim/KeyTable') do
  it { should be_file }
  its('mode') { should cmp '00640' }
  its('owner') { should eq 'opendkim' }
  its('content') { should match 'default._domainkey.example.com' }
end
describe file('/etc/opendkim/SigningTable') do
  it { should be_file }
  its('mode') { should cmp '00640' }
  its('owner') { should eq 'opendkim' }
  its('content') { should match 'default._domainkey.example.com' }
end
describe file('/etc/opendkim/TrustedHosts') do
  it { should be_file }
  its('mode') { should cmp '00640' }
  its('owner') { should eq 'opendkim' }
  its('content') { should match '::1' }
end
case os[:family]
when 'rhel', 'amazon'
  describe yum.repo('epel') do
    it { should exist }
    it { should be_enabled }
  end
end
