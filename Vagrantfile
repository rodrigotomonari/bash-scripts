Vagrant.configure("2") do |config|
  config.vm.define "ubuntu14", primary: true do |ubuntu14|
    ubuntu14.vm.box = "ubuntu/trusty64"
    ubuntu14.vm.network :forwarded_port, guest: 80, host: 8014
    ubuntu14.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y apache2 libapache2-mod-fastcgi php5 php5-fpm links2 mysql-server mysql-client monit
      a2enmod actions fastcgi alias rewrite
      service apache2 restart

      echo "set httpd port 2812 and use address localhost allow localhost" > /etc/monit/conf.d/daemon
      service monit reload
    SHELL
  end

  config.vm.define "ubuntu16", primary: true do |ubuntu16|
    ubuntu16.vm.box = "ubuntu/xenial64"
    ubuntu16.vm.network :forwarded_port, guest: 80, host: 8016
    ubuntu16.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y apache2 libapache2-mod-fastcgi php7.0 php7.0-fpm links2 mysql-server mysql-client monit
      a2enmod actions fastcgi alias rewrite
      service apache2 restart

      echo "set httpd port 2812 and use address localhost allow localhost" > /etc/monit/conf.d/daemon
      service monit reload
    SHELL
  end
end
