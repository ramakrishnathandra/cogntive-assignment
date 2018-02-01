# This is a Chef recipe file. It can be used to specify resources which will
# apply configuration to a server.

require 'mixlib/shellout'

environment = Chef::DataBagItem.load('cogntive', 'cogntive')
node.default['cogntiveapp']['notification'] = environment['snstopicarn']

execute "apt-get-update" do
   command "apt-get update"
end

apt_repository "docker" do
  uri "https://apt.dockerproject.org/repo"
  distribution "ubuntu-trusty"
  components ["main"]
  keyserver "p80.pool.sks-keyservers.net"
  key "58118E89F3A912897C070ADBF76221572C52609D"
end

package "docker-engine"

group "docker" do
  action :modify
  members "ubuntu"
  append true
end

user 'www-data'
group 'www-data'

['awscli'].each do |p|
  package p do
    action :install
  end
end

script "cogntive_app_docker" do
  interpreter "bash"
  code <<-EOH
    docker pull ramakrishna2106/cogntive:latest
    docker run --name #{node["cogntive"]["name"]} -p 80:80 -d ramakrishna2106/cogntive:latest
    touch /home/ubuntu/cogntiveapp.executed
    EOH
  notifies :create, "template[sns notification.sh]", :delayed
  not_if do ::File.exists?('/home/ubuntu/cogntiveapp.executed') end
end

cron 'send_notification' do
  minute '*'
  hour '*'
  day '*'
  month '*'
  weekday '*'
  user 'root'
  command '/opt/snsnotification.sh'
  action :create
end

template 'sns notification.sh' do
  path '/opt/snsnotification.sh'
  source "snsnotification.sh.erb"
  cookbook 'cogntiveapp'
  variables lazy {{ :snstopicarn => node["cogntiveapp"]["notification"] }}
  mode '0755'
end
