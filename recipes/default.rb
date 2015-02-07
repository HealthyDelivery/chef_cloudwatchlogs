#
# Cookbook Name:: chef_cloudwatchlogs
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

# Chef::Log.info('node.to_json')
# Chef::Log.info(node.to_json)

node_data = JSON.parse(node.to_json)
rails_env = node_data['default']['deploy']['platejoy']['environment']['RAILS_ENV']
rails_log_dir = node_data['normal']['deploy']['platejoy']['environment_variables']['PRODUCTION_LOG_PATH']

logs = []

logs << {
  name: 'rails',
  group: "#{rails_env}_rails",
  path:  "#{rails_log_dir}#{rails_env}.log"
}

layers_this_instance = node_data['normal']['opsworks']['instance']['layers']

if layers_this_instance.include?('rails-app')
  subdomain = rails_env == 'production' ? 'www' : 'staging'
  logs << {
    name: 'nginx',
    group: "#{rails_env}_nginx",
    path:  "/var/log/nginx/#{subdomain}.platejoy.com.access.log"
  }
end

if layers_this_instance.include?('cronjob_ruby')
  logs << {
    name: 'cronjob',
    group: "#{rails_env}_cronjob",
    path:  '/var/mail/root'
  }
end

template "/tmp/cwlogs.cfg" do
  cookbook "logs"
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
  command "/opt/aws/cloudwatch/awslogs-agent-setup.py -n -r us-east-1 -c /tmp/cwlogs.cfg"
  not_if { system "pgrep -f aws-logs-agent-setup" }
end
