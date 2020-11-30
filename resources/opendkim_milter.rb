resource_name :opendkim_milter
provides :opendkim_milter

property :service_name, String, name_property: true
property :base_path, String, desired_state: false, default: '/etc/opendkim'
property :config, Hash, required: true, desired_state: false
property :user_targets, Array, desired_state: false, default: []
property :user_options, Array, desired_state: false, default: []
property :owner, String, desired_state: false, default: 'opendkim'
property :group, String, desired_state: false, default: 'opendkim'
property :databag_defaults, Hash, desired_state: false
property :databag_files, Hash, desired_state: false
property :config_files, Hash, desired_state: false
property :key_files, Hash, desired_state: false

default_action :deploy

require 'chef-vault'

action :deploy do
  pid_file = new_resource.config.key?('PidFile') ? new_resource.config['PidFile'] : "/var/run/opendkim/#{new_resource.service_name}.pid"
  ensure_dir(pid_file)
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
    action :enable
    subscribes :restart, "template[#{new_resource.service_name}_config]"
  end
  if property_is_set?(:databag_files)
    new_resource.databag_files.each do |file_path, prop|
      ensure_dir("#{new_resource.base_path}/#{file_path}")
      databag = pick('databag', prop)
      item = pick('item', prop)
      file "#{new_resource.service_name}_#{file_path}" do
        path "#{new_resource.base_path}/#{file_path}"
        if ChefVault::Item.vault?(databag, item)
          content chef_vault_item(databag, item)[pick('field', prop)]
        else
          content data_bag_item(databag, item)[pick('field', prop)]
        end
        mode pick('mode', prop)
        owner new_resource.owner
        group new_resource.group
        notifies :restart, "service[#{new_resource.service_name}]"
      end
    end
  end
  if property_is_set?(:config_files)
    new_resource.config_files.each do |file_path, prop|
      ensure_dir("#{new_resource.base_path}/#{file_path}")
      file "#{new_resource.service_name}_#{file_path}" do
        path "#{new_resource.base_path}/#{file_path}"
        content get_content(prop)
        mode '0640'
        owner new_resource.owner
        group new_resource.group
        notifies :restart, "service[#{new_resource.service_name}]"
      end
    end
  end
  if property_is_set?(:key_files)
    new_resource.key_files.each do |file_path, prop|
      ensure_dir("#{new_resource.base_path}/#{file_path}")
      file "#{new_resource.service_name}_#{file_path}" do
        path "#{new_resource.base_path}/#{file_path}"
        content get_content(prop)
        mode '0400'
        owner new_resource.owner
        group new_resource.group
        notifies :restart, "service[#{new_resource.service_name}]"
      end
    end
  end
  service "#{new_resource.service_name}_start" do
    service_name new_resource.service_name
    action :start
  end
end

action_class do
  def ensure_dir(file)
    directory "#{file}_directory" do
      path ::File.dirname(file)
      mode '0750'
      owner new_resource.owner
      group new_resource.group
      recursive true
    end
  end

  def pick(name, prop)
    if prop.key?(name)
      prop[name]
    elsif property_is_set?(:databag_defaults) && new_resource.databag_defaults.key?(name)
      new_resource.databag_defaults[name]
    elsif name == 'mode'
      '0640'
    else
      Chef::Application.fatal!("Essential option '#{name}' is undefined neither in databags_default nor in databag_files", 2)
    end
  end

  def get_content(content)
    if content.is_a?(Array)
      (content + ['']).join("\n")
    elsif content.is_a?(Hash)
      (content.map { |k, v| "#{k} #{v}" } + ['']).join("\n")
    else
      content
    end
  end
end
