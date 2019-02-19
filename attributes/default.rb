default['opendkim-milter']['package'] = 'opendkim'
if platform_family?('rhel') || platform_family?('amazon')
  default['opendkim-milter']['os_targets'] = %w(syslog.target)
  force_default['yum-epel']['repos'] = %w(epel)
else
  default['opendkim-milter']['os_targets'] = []
end

default['opendkim-milter']['services']['opendkim'] = {
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
