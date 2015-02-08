#
# Cookbook Name:: chef_cloudwatchlogs
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

rails_env = node['deploy']['platejoy']['environment']['RAILS_ENV']
rails_log_dir = node['deploy']['platejoy']['environment_variables']['PRODUCTION_LOG_PATH']

logs = []
group_name = "platejoy-#{rails_env}"

layers_this_instance = node['opsworks']['instance']['layers']

if layers_this_instance.include?('rails-app')
  subdomain = rails_env == 'production' ? 'www' : 'staging'
  logs << {
    name: 'nginx',
    group: group_name,
    path:  "/var/log/nginx/#{subdomain}.platejoy.com.access.log"
  }

  logs << {
    name: 'rails-web',
    group: group_name,
    path:  "#{rails_log_dir}/#{rails_env}.log"
  }

else
  logs << {
    name: 'rails-background',
    group: group_name,
    path:  "#{rails_log_dir}/#{rails_env}.log"
  }
end

if layers_this_instance.include?('cronjob_ruby')
  logs << {
    name: 'cronjob',
    group: group_name,
    path:  '/var/mail/root'
  }
end

template "/tmp/cwlogs.cfg" do
  cookbook "chef_cloudwatchlogs"
  source "cwlogs.cfg.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    logs: logs
  )
end

directory "/opt/aws/cloudwatch" do
  recursive true
end

remote_file "/opt/aws/cloudwatch/awslogs-agent-setup.py" do
  source "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py"
  mode "0755"
end

execute "Install CloudWatch Logs agent" do
  command "/opt/aws/cloudwatch/awslogs-agent-setup.py -n -r us-west-2 -c /tmp/cwlogs.cfg"
  not_if { system "pgrep -f aws-logs-agent-setup" }
end
