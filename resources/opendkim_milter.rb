resource_name :opendkim_milter

property :service_name, String, name_property: true
property :base_path, String, desired_state: false, default: '/etc/opendkim'
property :config, Hash, required: true, desired_state: false
property :user_targets, Array, desired_state: false, default: []
property :user_options, Array, desired_state: false, default: []
property :owner, String, desired_state: false, default: 'opendkim'
property :group, String, desired_state: false, default: 'opendkim'
property :databag_files, Hash, desired_state: false
property :config_files, Hash, desired_state: false

default_action :deploy

require 'chef-vault'

action :deploy do
  pid_file = new_resource.config.key?('PidFile') ? new_resource.config['PidFile'] : "/var/run/opendkim/#{new_resource.service_name}.pid"
  directory ::File.dirname(pid_file) do
    mode '0750'
    owner new_resource.owner
    group new_resource.group
    recursive true
  end
  directory new_resource.base_path do
    mode '0750'
    owner new_resource.owner
    group new_resource.group
    recursive true
  end
  execute 'run_daemon_reload' do
    command 'systemctl daemon-reload'
    action :nothing
  end
  template "/etc/systemd/system/#{new_resource.service_name}.service" do
    mode   '0644'
    owner  'root'
    group  'root'
    source 'systemd_service.erb'
    variables(
      conf_file: "#{new_resource.base_path}/#{new_resource.service_name}.conf",
      pid_file: pid_file,
      user_targets:  new_resource.user_targets,
      user_options: new_resource.user_options,
      umask: new_resource.config['Umask'],
      owner: new_resource.owner,
      group: new_resource.group
    )
    notifies :run, 'execute[run_daemon_reload]', :immediately
  end
  template "#{new_resource.service_name}_config" do
    path   "#{new_resource.base_path}/#{new_resource.service_name}.conf"
    mode   '0640'
    owner  new_resource.owner
    group  new_resource.group
    source 'key_value.erb'
    variables(
      config: new_resource.config
    )
    notifies :restart, "service[#{new_resource.service_name}]"
  end
  service new_resource.service_name do
    action [ :enable, :start ]
    subscribes :restart, "template[#{new_resource.service_name}_config]"
  end
  if property_is_set?(:databag_files)
    new_resource.databag_files.each do |path, prop|
      file "#{new_resource.service_name}_#{path}" do
        path "#{new_resource.base_path}/#{path}"
        if ChefVault::Item.vault?(prop['databag'], prop['item'])
          content chef_vault_item(prop['databag'], prop['item'])
        else
          content data_bag_item(prop['databag'], prop['item'])
        end
        mode prop.key?('mode') ? prop['mode'] : '0640'
        owner new_resource.owner
        group new_resource.group
        notifies :restart, "service[#{new_resource.service_name}]"
      end
    end
  end
  if property_is_set?(:config_files)
    new_resource.config_files.each do |path, prop|
      file_content = ''
      if prop.is_a?(Array)
        file_content = prop.join("\n")
      elsif prop.is_a?(Hash)
        prop.each do |k, v|
          file_content += "#{k} #{v}\n"
        end
      else
        file_content = prop
      end
      file "#{new_resource.service_name}_#{path}" do
        path "#{new_resource.base_path}/#{path}"
        content file_content
        mode '0640'
        owner new_resource.owner
        group new_resource.group
        notifies :restart, "service[#{new_resource.service_name}]"
      end
    end
  end
end