run 'gem install bundler --pre'

gem 'figaro'

if yes?('Would you like to use HAML in this project?')
  gem 'haml-rails'
end

if yes?('Would you like to install Skeleton CSS framework?')
  gem 'skeleton-rails'
end

run "bundle"

route "root 'home#index'"

if yes?('Are you using Vagrant in this project?')
  run 'vagrant init ubuntu/trusty32'

  remove_file 'Vagrantfile'
  create_file 'Vagrantfile' do <<-CODE
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure('2') do |config|
  config.vm.box      = 'ubuntu/trusty32'

  config.vm.network :forwarded_port, guest: 5432, host: 6543
  config.vm.network :forwarded_port, guest: 6379, host: 6379

  config.vm.provision :shell, path: 'bootstrap.sh', keep_color: true

  config.vm.provider "virtualbox" do |v|
    host = RbConfig::CONFIG['host_os']

    # Give VM 1/4 system memory & access to all cpu cores on the host
    if host =~ /darwin/
      cpus = `sysctl -n hw.ncpu`.to_i
      # sysctl returns Bytes and we need to convert to MB
      mem = `sysctl -n hw.memsize`.to_i / 1024 / 1024 / 4
    elsif host =~ /linux/
      cpus = `nproc`.to_i
      # meminfo shows KB and we need to convert to MB
      mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024 / 4
    else # sorry Windows folks, I can't help you
      cpus = 2
      mem = 1024
    end

    v.customize ["modifyvm", :id, "--memory", mem]
    v.customize ["modifyvm", :id, "--cpus", cpus]
  end
end
CODE
  end

  create_file 'bootstrap.sh' do <<-CODE
#!/usr/bin/env bash

sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8

sudo apt-get update

# postgres
echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main " | sudo tee -a /etc/apt/sources.list.d/pgdg.list
sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y --force-yes postgresql-9.4 libpq-dev
echo '# "local" is for Unix domain socket connections only
local   all             all                                  trust
# IPv4 local connections:
host    all             all             0.0.0.0/0            trust
# IPv6 local connections:
host    all             all             ::/0                 trust' | sudo tee /etc/postgresql/9.4/main/pg_hba.conf
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.4/main/postgresql.conf
sudo /etc/init.d/postgresql restart
sudo su - postgres -c 'createuser -s vagrant'

echo "All done installing!

Next steps: type 'vagrant ssh' to log into the machine."
CODE
  end

  run 'vagrant up'

  inside 'config' do
    remove_file 'database.yml'
    create_file 'database.yml' do <<-CODE
default: &default
  host: 0.0.0.0
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  port: 6543
  timeout: 5000

development:
  <<: *default
  database: #{app_name}_development
  username: vagrant

test:
  <<: *default
  database: #{app_name}_test
  username: vagrant

production:
  <<: *default
  database: #{app_name}_production
  username: #{app_name}
  password: <%= ENV['#{app_name.upcase}_DATABASE_PASSWORD'] %>
CODE
    end
  end
end

rails_command "db:create"

if yes?('Would you like to install Devise?')
  gem 'devise'
  generate 'devise:install'
  model_name = ask('What do you want to call the first user model? [user]')
  model_name = 'user' if model_name.blank?
  generate 'devise', model_name
end

git :init

remove_file .gitignore
create_file .gitignore do <<-CODE
# Ignore bundler config.
/.bundle

# Ignore all logfiles and tempfiles.
/log/*
/tmp/*
!/log/.keep
!/tmp/.keep

# Ignore Byebug command history file.
.byebug_history

# Ignore application configuration
/config/application.yml

.vagrant

/public/system/*

.DS_Store
CODE

git add: "."
git commit: "-a -m 'Initial commit'"

git_repo = ask('Please specify the URL of your github repository: ')
if git_repo.blank?
  p 'No repository specified. You will have to manually add an origin remote'
else
  git remote: "add origin #{git_repo}"
end
