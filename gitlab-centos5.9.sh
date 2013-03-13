#!/bin/bash
# installer for gitlab on centos 5.9 
# @Version 1.0
#####################################
# database: mysql
# server: apache2
# ssh: openssh-server
#
########################################## 
# 
# create  two users, default git user and user gitlab who 
# used to manage git
# 
##########################################################

export PATH=$PATH:/sbin:/usr/sbin/

GL_HOSTNAME=$HOSTNAME
GL_MYSQL_USERNAME="gitlab"
GL_MYSQL_PASSWORD="gitlab"
GL_MYSQL_DATABASE="gitlab"

die()
{
  # $1 - the exit code
  # $2 $... - the message string

  retcode=$1
  shift
  printf >&2 "%s\n" "$@"
  exit $retcode
}

echo "Check OS (we check if the kernel release contains el5)"
uname -r | grep "el5" || die 1 "Not RHEL or CentOS"

echo "Check if we are root"
[[ $EUID -eq 0 ]] || die 1 "This script must be run as root"

# Disable SELinux 
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

# Turn off SELinux in this session
# setenforce 0
echo 0 > /selinux/enforce

# turn off firewall
/etc/init.d/iptables save
# delete all roles
/sbin/iptables --flush


# Install epel-release
rpm -Uvh http://mirrors.kernel.org/fedora-epel/5/i386/epel-release-5-4.noarch.rpm

# update system
echo "updating system"
yum update -y

# install necessory dependencies
yum -y groupinstall 'Development Tools' 'Development Libraries'
yum -y install git vim-enhanced httpd readline readline-devel ncurses-devel gdbm-devel glibc-devel tcl-devel openssl-devel curl-devel expat-devel db4-devel byacc sqlite-devel gcc-c++ libyaml libyaml-devel libffi libffi-devel libxml2 libxml2-devel libxslt libxslt-devel libicu libicu-devel python-devel redis sudo mysql-server wget mysql-devel crontabs logwatch logrotate sendmail-cf sqlite-devel sqlite

# Install sqlite-devel from atrpms (sqlite > 3.3 is not provided by epel or centos)
# rpm -Uvh http://dl.atrpms.net/el5-$(uname -i)/atrpms/testing/sqlite-3.6.20-1.el5.$(uname -i).rpm
# rpm -Uvh http://dl.atrpms.net/el5-$(uname -i)/atrpms/testing/sqlite-devel-3.6.20-1.el5.$(uname -i).rpm

# database 

# ssh set
echo "config ssh"
yum install -y openssh-server
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication no/#PasswordAuthentication yes/g' /etc/ssh/sshd_config

# start ssh service
/etc/init.d/sshd start

# install ruby 
echo "install ruby"
mkdir /tmp/ruby && cd /tmp/ruby
wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p327.tar.gz
tar xfvz ruby-1.9.3-p327.tar.gz
cd ruby-1.9.3-p327
./configure
make
make install

# modify ruby's source  
echo "change gem source"
# delete default source 
gem sources -r https://rubygems.org/
# add taobao's source 
gem sources -a http://ruby.taobao.org/

# install bundler gem
echo "install bundler"
gem install bundler

# install python 2.7.3
echo "install python 2.7.3"
mkdir /tmp/python && cd /tmp/python
wget http://www.python.org/ftp/python/2.7.3/Python-2.7.3.tgz
tar xfvz Python-2.7.3.tgz
cd /tmp/python
cd Python-2.7.3
./configure
make
make install

# addusers
# add git
echo "create user git and gitlab"
/usr/sbin/adduser -r --shell /bin/bash --comment 'Git Version Control' --create-home --home-dir /home/git git

# add gitlab 
/usr/sbin/adduser --shell /bin/bash --comment 'GitLab user' --create-home --home-dir /home/gitlab gitlab

# add gitlab to group git
/usr/sbin/usermod -a -G git gitlab

# generate ssh key
echo "generate ssh key"
su - gitlab -c 'ssh-keygen -q -N "" -t rsa -f ~/.ssh/id_rsa'



#### install gitolite 
#*** i failed here few times, the main problem is the versin of gitolite was no correct for gitlab
cd /home/git
echo "clone gitolite "
su - git -c 'git clone -b gl-v320 https://github.com/gitlabhq/gitolite.git /home/git/gitolite'

# set gitlab as gitolite's admin
su - git -c 'mkdir /home/git/bin'
su - git -c 'printf "%b\n%b\n" "PATH=\$PATH:/home/git/bin" "export PATH" >> /home/git/.profile'

su - git -c 'gitolite/install -ln /home/git/bin'

# cp gitlab's ssh to git 
cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
chmod 0444 /home/git/gitlab.pub

# setup gitolite
su - git -c 'PATH=/home/git/bin:$PATH; gitolite setup -pk /home/git/gitlab.pub'

# modify gitolite accessbility
chmod 750 /home/git/.gitolite/
chown -R git:git /home/git/.gitolite/

# modify repositories's accessbility
chmod -R ug+rwX,o-rwx /home/git/repositories/
chmod -R ug-s /home/git/repositories/
chown -R git:git /home/git/repositories/
find /home/git/repositories/ -type d -print0 | xargs -0 chmod g+s

chmod g+x /home/git

# config gitlab 
# su - gitlab -c 'ssh git@localhost'

#***** test
# git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin
# rm -rf /tmp/gitolite-admin
echo "end"
echo "***********************************************************"



#### install gitlab 
echo "install gitlab "
echo "start"
cd /home/gitlab/
echo "clone gitlabhq source"
su - gitlab -c 'git clone https://github.com/gitlabhq/gitlabhq.git gitlab'
su - gitlab -c 'cd /home/gitlab/gitlab && git checkout 4-0-stable'

cd /home/gitlab/gitlab 
echo "config gitlab.yml"
su - gitlab -c 'cp /home/gitlab/gitlab/config/gitlab.yml.example /home/gitlab/gitlab/config/gitlab.yml'
sed -i "s/  host: localhost/  host: $GL_HOSTNAME/g" /home/gitlab/gitlab/config/gitlab.yml

echo "config unicorm.rb"
su - gitlab -c 'cp /home/gitlab/gitlab/config/unicorn.rb.example /home/gitlab/gitlab/config/unicorn.rb'
su - gitlab -c 'echo "listen 127.0.0.1:3000" >> /home/gitlab/gitlab/config/unicorn.rb'

# mysql
echo "config database.yml"
/etc/init.d/mysqld start
su - gitlab -c 'cp /home/gitlab/gitlab/config/database.yml.mysql /home/gitlab/gitlab/config/database.yml'
sed -i "s/secure password/$GL_MYSQL_PASSWORD/g" /home/gitlab/gitlab/config/database.yml
sed -i "s/username: root/username: $GL_MYSQL_USERNAME/g" /home/gitlab/gitlab/config/database.yml
sed -i "s/database: gitlabhq_production/database: $GL_MYSQL_DATABASE/g" /home/gitlab/gitlab/config/database.yml


# start redis service 
/etc/init.d/redis start

echo "install charlock_holmes"
cd /home/gitlab/gitlab
gem install charlock_holmes --version '0.6.9'

cd /home/gitlab/gitlab/
echo "installing bundle"
# modify Gemfile to set the bundle source 
sed -i 's/source "http:\/\/rubygems.org"/source "http:\/\/ruby.taobao.org"/g' Gemfile

su - gitlab -c 'cd /home/gitlab/gitlab/ && bundle install --deployment --without development test postgres'

# config git count
su - gitlab -c 'git config --global user.name "GitLab"'
su - gitlab -c 'git config --global user.email "gitlab@localhost"'

# config gitlab hooks
echo "set hooks"
cd /home/gitlab/gitlab
cp ./lib/hooks/post-receive /home/git/.gitolite/hooks/common/post-receive
chown git:git /home/git/.gitolite/hooks/common/post-receive

# init database 
cd /home/gitlab/gitlab

echo "init database"
# here will output username and password
su - gitlab -c 'cd /home/gitlab/gitlab && bundle exec rake gitlab:setup RAILS_ENV=production'

# clone gitlab script 
echo "downloading gitlab script"
curl https://raw.github.com/gitlabhq/gitlab-recipes/4-0-stable/init.d/gitlab > /etc/init.d/gitlab
chmod +x /etc/init.d/gitlab

echo "starting gitlab service"
# start gitlab service 
/etc/init.d/gitlab start
/sbin/chkconfig gitlab on

# test 
# su gitlab 
# cd /home/gitlab/gitlab 
# test some config info 
# bundle exec rake gitlab:env:info RAILS_ENV=production
# all yes no no permitted
# bundle exec rake gitlab:check RAILS_ENV=production
echo "end"
echo "***********************************************************"



#### config apache 
# proxy , default address is 127.0.0.1:3000
echo "config apache"
echo "start"
cat >  /etc/httpd/conf.d/gitlab.conf << EOF
<VirtualHost *:80>
  ServerName $GL_HOSTNAME
  ProxyRequests Off
    <Proxy *>
       Order deny,allow
       Allow from all
    </Proxy>
    ProxyPreserveHost On
    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/
</VirtualHost>
EOF
echo "end"
echo "***********************************************************"



#### restart services
echo "restart all serivces"
echo "start"
/etc/init.d/gitlab restart
/etc/init.d/httpd restart

/sbin/chkconfig redis on
/sbin/chkconfig sshd on
/sbin/chkconfig gitlab on
/sbin/chkconfig mysqld on
/sbin/chkconfig httpd on
echo "end"
echo "***********************************************************"



echo "Point your browser to:" 
echo "http://$GL_HOSTNAME (or: http://<host-ip>)"
echo "Default admin username: admin@local.host"
echo "Default admin password: 5iveL!fe"


#### references
echo "references"
echo "https://gitcafe.com/leewind/leewind-project-note/blob/master/git/gitlab-installation-centos.md"

exit 0
