#
# Cookbook:: opendkim-milter
# Spec:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.

require 'spec_helper'

describe 'opendkim-milter::default' do
  context 'When all attributes are default, on Ubuntu 18.04' do
    let(:chef_run) do
      # for a complete list of available platforms and versions see:
      # https://github.com/customink/fauxhai/blob/master/PLATFORMS.md
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '18.04') do |node|
        node.normal['opendkim-milter']['services']['opendkim'] = {
          service_name: 'opendkim',
          config: {
            PidFile:          '/var/run/opendkim/opendkim.pid',
            Mode:             'v',
            Syslog:           'yes',
            SyslogSuccess:    'yes',
            LogWhy:           'yes',
            UserID:           'opendkim:opendkim',
            Socket:           'local:/var/run/opendkim/opendkim.sock',
            Umask:            '007',
            OversignHeaders:  'From',
          },
          config_files: {
            TrustedHosts: %w(127.0.0.1 ::1),
            KeyTable: {
              '#default._domainkey.example.com': 'example.com:default:/etc/opendkim/keys/default.private',
            },
            SigningTable: {
              '#*@example.com': 'default._domainkey.example.com',
            },
          },
        }
      end
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
    it 'install the packages' do
      expect(chef_run).to install_package('opendkim')
    end
    it 'creates application services' do
      expect(chef_run).to deploy_opendkim_milter('opendkim').with(
        config: {
          'PidFile' =>          '/var/run/opendkim/opendkim.pid',
          'Mode' =>             'v',
          'Syslog' =>           'yes',
          'SyslogSuccess' =>    'yes',
          'LogWhy' =>           'yes',
          'UserID' =>           'opendkim:opendkim',
          'Socket' =>           'local:/var/run/opendkim/opendkim.sock',
          'Umask' =>            '007',
          'OversignHeaders' =>  'From',
        },
        'config_files' => {
          'TrustedHosts' => %w(127.0.0.1 ::1),
          'KeyTable' => { '#default._domainkey.example.com' => 'example.com:default:/etc/opendkim/keys/default.private' },
          'SigningTable' => { '#*@example.com' => 'default._domainkey.example.com' },
        }
      )
    end
  end
end
