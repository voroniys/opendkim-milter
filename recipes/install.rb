include_recipe 'yum-epel' if platform_family?('rhel') || platform_family?('amazon')
package node['opendkim-milter']['package']
