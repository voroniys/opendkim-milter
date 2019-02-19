default['opendkim-milter']['package'] = 'opendkim'
if platform_family?('rhel') || platform_family?('amazon')
  default['opendkim-milter']['os_targets'] = %w(syslog.target)
  force_default['yum-epel']['repos'] = %w(epel)
else
  default['opendkim-milter']['os_targets'] = []
end

default['opendkim-milter']['services'] = {}
