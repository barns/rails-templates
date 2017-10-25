gem 'figaro'

if yes?('Would you like to use HAML in this project?')
  gem 'haml-rails'
end

if yes?('Would you like to install Skeleton CSS framework?')
  gem 'skeleton-rails'
end

if yes?('Would you like to install Devise?')
  gem 'devise'
  generate 'devise:install'
  model_name = ask('What do you want to call the first user model? [user]')
  model_name = 'user' if model_name.blank?
  generate 'devise', model_name
end

route "root 'home#index'"

if yes?('Are you using Vagrant in this project?')
  file 'bootstrap.sh', <<-CODE
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

  run "vagrant init"
  run "vagrant up"
end

rails_command "db:create"

run "bundle"

git :init
git add: "."
git commit: "-a -m 'Initial commit'"

git_repo = ask('Please specify the URL of your github repository: ')
if git_repo.blank?
  p 'No repository specified. You will have to manually add an origin remote'
else
  git remote: "add origin #{git_repo}"
end
