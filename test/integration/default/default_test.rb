# # encoding: utf-8

# Inspec test for recipe opendkim-milter::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/
base_path = '/opt/dkim'

describe systemd_service('verifier.service') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end
describe systemd_service('signer.service') do
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
describe directory(base_path) do
  it { should exist }
  its('mode') { should cmp '00750' }
  its('owner') { should eq 'opendkim' }
  its('group') { should eq 'bin' }
end
describe directory('/var/run/opendkim') do
  it { should exist }
  its('mode') { should cmp '00750' }
  its('owner') { should eq 'opendkim' }
  its('group') { should eq 'bin' }
end
describe file("#{base_path}/verifier.conf") do
  it { should be_file }
  its('mode') { should cmp '00640' }
  its('owner') { should eq 'opendkim' }
  its('content') { should match 'verifier.sock' }
end
describe file("#{base_path}/signer.conf") do
  it { should be_file }
  its('mode') { should cmp '00640' }
  its('owner') { should eq 'opendkim' }
  its('content') { should match 'signer.sock' }
end
describe file("#{base_path}/KeyTable") do
  it { should be_file }
  its('mode') { should cmp '00640' }
  its('owner') { should eq 'opendkim' }
  its('content') { should match 'default._domainkey.example.com' }
end
describe file("#{base_path}/SigningTable") do
  it { should be_file }
  its('mode') { should cmp '00640' }
  its('owner') { should eq 'opendkim' }
  its('content') { should match 'default._domainkey.example.com' }
end
describe file("#{base_path}/TrustedHosts") do
  it { should be_file }
  its('mode') { should cmp '00640' }
  its('owner') { should eq 'opendkim' }
  its('content') { should match '::1' }
end
describe directory("#{base_path}/keys") do
  it { should exist }
  its('mode') { should cmp '00750' }
  its('owner') { should eq 'opendkim' }
  its('group') { should eq 'bin' }
end
describe file("#{base_path}/keys/example.private") do
  it { should be_file }
  its('mode') { should cmp '00600' }
  its('owner') { should eq 'opendkim' }
  its('content') { should match 'BEGIN RSA PRIVATE KEY' }
end
case os[:family]
when 'rhel', 'amazon'
  describe yum.repo('epel') do
    it { should exist }
    it { should be_enabled }
  end
end
