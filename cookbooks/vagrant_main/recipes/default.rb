include_recipe "apt"
include_recipe "git"
include_recipe "oh-my-zsh"
include_recipe "apache2"
include_recipe "apache2::mod_rewrite"
include_recipe "apache2::mod_ssl"
include_recipe "mysql::server"
include_recipe "php"
include_recipe "apache2::mod_php5"
include_recipe "database::mysql"
include_recipe "nodejs::install_from_binary"
include_recipe "nodejs::npm"

# Install packages
%w{ debconf vim subversion curl tmux make g++ libsqlite3-dev }.each do |a_package|
  package a_package
end

# Install ruby gems
%w{ rake mailcatcher compass }.each do |a_gem|
  gem_package a_gem
end

# Install node packages
%w{ yo generator-ember phantomjs@v1.9.1-9 }.each do |a_node_package|
  npm_package a_node_package
end

cookbook_file "/etc/init/phantomjs.conf" do
  source "phantomjs.conf"
end

execute "start_phantomjs" do
  command "start phantomjs"
  ignore_failure true
end

# Generate selfsigned ssl
execute "make-ssl-cert" do
  command "make-ssl-cert generate-default-snakeoil --force-overwrite"
  ignore_failure true
  action :nothing
end

# Configure sites
sites = data_bag("sites")

sites.each do |name|
  site = data_bag_item("sites", name)

  # Add site to apache config
  web_app site["host"] do
    template "sites.conf.erb"
    server_name site["host"]
    server_aliases site["aliases"]
    docroot "/vagrant/public/#{site["host"]}"
  end

   # Add site info in /etc/hosts
   bash "hosts" do
     code "echo 127.0.0.1 #{site["host"]} #{site["aliases"].join(' ')} >> /etc/hosts"
   end
end

# Disable default site
apache_site "default" do
  enable false
end

# Install phpmyadmin
cookbook_file "/tmp/phpmyadmin.deb.conf" do
  source "phpmyadmin.deb.conf"
end
bash "debconf_for_phpmyadmin" do
  code "debconf-set-selections /tmp/phpmyadmin.deb.conf"
end
package "phpmyadmin"

# Install Xdebug
php_pear "xdebug" do
  action :install
end
template "#{node['php']['ext_conf_dir']}/xdebug.ini" do
  source "xdebug.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :restart, resources("service[apache2]"), :delayed
end

# Install Webgrind
git "/var/www/webgrind" do
  repository 'git://github.com/jokkedk/webgrind.git'
  reference "master"
  action :sync
end
template "#{node[:apache][:dir]}/conf.d/webgrind.conf" do
  source "webgrind.conf.erb"
  owner "root"
  group "root"
  mode 0644
  action :create
  notifies :restart, resources("service[apache2]"), :delayed
end

# Install php-curl
package "php5-curl" do
  action :install
end

# Install php-pspell
package "php5-pspell" do
  action :install
end

# Get eth1 ip
eth1_ip = node[:network][:interfaces][:eth1][:addresses].select{|key,val| val[:family] == 'inet'}.flatten[0]

# Setup MailCatcher
bash "mailcatcher" do
  code "mailcatcher --http-ip #{eth1_ip} --smtp-port 25"
end
template "#{node['php']['ext_conf_dir']}/mailcatcher.ini" do
  source "mailcatcher.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :restart, resources("service[apache2]"), :delayed
end

magic_shell_environment 'APPLICATION_ENVIRONMENT' do
  value 'development'
end

# Install PHPUnit
php_pear_channel "pear.phpunit.de" do
  action :discover
end
php_pear_channel "pear.symfony.com" do
  action :discover
end
php_pear "PHPUnit" do
  channel "phpunit"
  action :install
end

# Install Phing
php_pear_channel "pear.phing.info" do
  action :discover
end
php_pear "phing" do
  channel "phing"
  action :install
end

# Take control of apache's php.ini
template "/etc/php5/apache2/php.ini" do
    source "php.ini.erb"
    owner "root"
    group "root"
    mode 0644
    notifies :restart, "service[apache2]", :immediately
end


mysql_connection_info = {
  :host => "localhost",
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

# create the mysql databases
mysql_database 'ncareern' do
  connection mysql_connection_info
  action :create
end
mysql_database 'ncareern_test' do
  connection mysql_connection_info
  action :create
end

# create mysql user
mysql_database_user 'careers' do
  connection mysql_connection_info
  password 'careers'
  action :create
end

# grant all privileges on all databases/tables from localhost
mysql_database_user 'careers' do
  connection mysql_connection_info
  password 'careers'
  action :grant
end
