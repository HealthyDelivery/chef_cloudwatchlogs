rails_log_dir = '/srv/www/platejoy/current/log/'
rails_env = node[:environment][:framework_env]

logs = []

logs << {
  name: 'rails',
  group: "#{rails_env}_rails",
  path:  "#{rails_log_dir}#{rails_env}.log"
}

layers_this_instance = JSON.parse(node.to_json)['normal']['opsworks']['instance']['layers']

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
