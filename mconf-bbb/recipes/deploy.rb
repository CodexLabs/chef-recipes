# Cookbook Name:: mconf-bbb
# Recipe:: deploy
#
# Copyright 2012, mconf.org
#
# All rights reserved - Do Not Redistribute

execute "bbb-conf --stop" do
  user "root"
  action :run
  only_if do File.exists?("#{node[:mconf][:bbb][:deploy_dir]}/.deploy_needed") end
end

directory "#{node[:mconf][:bbb][:deploy_dir]}" do
  recursive true
  action :create
end

remote_file "#{Chef::Config[:file_cache_path]}/#{node[:mconf][:bbb][:file]}" do
  source "#{node[:mconf][:bbb][:url]}"
  mode "0644"
end

execute "unzip_bigbluebutton" do
  user "root"
  cwd "#{node[:mconf][:bbb][:deploy_dir]}"
  command "unzip -o -d #{node[:mconf][:bbb][:version]} -q #{Chef::Config[:file_cache_path]}/#{node[:mconf][:bbb][:file]}; mv #{node[:mconf][:bbb][:version]}/web/bigbluebutton-*.war #{node[:mconf][:bbb][:version]}/web/bigbluebutton.war"
  action :run
  only_if do File.exists?("#{node[:mconf][:bbb][:deploy_dir]}/.deploy_needed") end
end

timestamp = Time.new.strftime("%Y%m%d-%H%M%S")
backup_dir = "#{node[:mconf][:bbb][:deploy_dir]}/backup-#{timestamp}"

node[:bbb][:modules].each do |name|
  module_deploy_dir = "#{node["bbb"]["#{name}"]["deploy_dir"]}"
  module_backup_dir = "#{backup_dir}/#{name}"
  
  directory "#{backup_dir}/#{name}" do
    recursive true
    action :create
    only_if do File.exists?("#{node[:mconf][:bbb][:deploy_dir]}/.deploy_needed") end
  end
  
  # backup only the bbb related apps on /usr/local/bin/
  if "#{name}" == "config"
    backup_files = "bbb-*"
  else
    backup_files = "*"
  end
  
  execute "backup_module" do
    user "root"
    command "cp -r #{module_deploy_dir}/#{backup_files} #{module_backup_dir}"
    action :run
    only_if do File.exists?("#{node[:mconf][:bbb][:deploy_dir]}/.deploy_needed") end
  end
  
  execute "deploy_module" do
    user "root"
    cwd "#{node[:mconf][:bbb][:deploy_dir]}"
    command "cp -r #{node[:mconf][:bbb][:version]}/#{name}/* #{module_deploy_dir}"
    action :run
    only_if do File.exists?("#{node[:mconf][:bbb][:deploy_dir]}/.deploy_needed") end
  end
end

ruby_block "sleep until demo is deployed" do
  block do
    FileUtils.rm_rf "#{node[:bbb][:demo][:deploy_dir]}/demo"
    %x(service tomcat6 start)
    count = 15
    while not File.exists?("#{node[:bbb][:demo][:deploy_dir]}/demo") and count > 0 do
      sleep 1.0
      count -= 1
    end
  end
  only_if do File.exists?("#{node[:mconf][:bbb][:deploy_dir]}/.deploy_needed") end
end

#register deployed version
file "#{node[:mconf][:bbb][:deploy_dir]}/.deployed" do
  action :create
  content "#{node[:mconf][:bbb][:version]}"
end

execute "bbb-conf --setsalt #{node[:bbb][:salt]}; bbb-conf --setip #{node[:bbb][:server_addr]}" do
  user "root"
  action :run
  only_if do File.exists?("#{node[:mconf][:bbb][:deploy_dir]}/.deploy_needed") end
    notifies :run, "execute[restart bigbluebutton]", :delayed
end

#delete deploy flag after deployement
file "#{node[:mconf][:bbb][:deploy_dir]}/.deploy_needed" do
  action :delete
end

