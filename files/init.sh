#!/usr/bin/env bash

# DO ALL THE THINGS
# (•_•) / ( •_•)>⌐■-■ / (⌐■_■)
#
# @author Joshua Copeland <Josh@RemoteDevForce.com>

# Non-interactive shell
export DEBIAN_FRONTEND=noninteractive
export HOME=/root

## Set Timezone to UTC
timedatectl set-timezone UTC

## Install Misc Deps
echo "Installing misc binaries"
apt-get update
apt-get install -y git wget jq vim unzip ca-certificates

## Install Docker-CE
echo "Installing Docker"
groupadd docker
apt-get install -y apt-transport-https curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
#Make sure you are about to install from the Docker repo instead of the default Ubuntu 16.04 repo
apt-cache policy docker-ce
apt-get install -y docker-ce

## Install PHP 7.3
echo "Installing PHP 7.3"
apt-get install -y apt-transport-https lsb-release
apt-get install -y software-properties-common
add-apt-repository ppa:ondrej/php -y
apt-get update -y
echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu xenial main" > /etc/apt/sources.list.d/php.list
echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu xenial main"

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50
apt-get install -y php7.3 php7.3-xml php7.3-mbstring php7.3-curl php7.3-cli php7.3-common

## GetComposer.org
echo "Installing Composer"
apt-get install -y curl php-cli php-mbstring git unzip
echo "Loading composer"
curl -s https://getcomposer.org/installer | php
echo "Moving composer"
mv composer.phar /usr/local/bin/composer
echo "composer installed"

#####
## Install Java + Jenkins + Plugins
#####

## Install Oracle Java 8
echo "Installing Oracle Java 8"
apt-get install -y default-jre
apt-get install -y default-jdk
add-apt-repository ppa:webupd8team/java -y
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
apt-get update

## Install Jenkins
echo "Installing Jenkins"
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add - OK
echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list
apt-get update
add-apt-repository universe -y
apt-get install -y jenkins --allow-unauthenticated

# Replace Config to skip Jenkins Setup
echo "Removing Jenkins Security"
sed -i -e 's#^JAVA_ARGS="-Djava.awt.headless=true"#JAVA_ARGS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"#' /etc/default/jenkins
# Delete config file so a new one is generated without security enabled
if grep -q "<authorizationStrategy class=\"hudson.security.FullControlOnceLoggedInAuthorizationStrategy\">" /var/lib/jenkins/config.xml; then
    rm /var/lib/jenkins/config.xml
fi

echo "Setting up Jenkins"
# Chown it over to the jenkins user
chown -h jenkins:root /var/lib/jenkins

# Download Jenkins Jar so that we can run commands from the CLI to Jenkins
printf '%s\n' 'Waiting for Jenkins to restart'
service jenkins restart  || {
    printf '%s\n' 'Failed to Start Jenkins'
    exit 1
}

# Set Jenkins to autostart on reboot
printf  '%s\n' 'Adding Jenkins to update-rc.d'
update-rc.d jenkins defaults || {
    printf '%s\n' 'Failed to add Jenkins to update-rc.d'
    exit 1
}

# Fetch the Jenkins CLI jar
until wget -O /root/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar; do
    echo "Trying to download jenkins-cli.jar attempt."
    sleep 10
done

# Test Jar installation
printf '%s\n' 'Testing Jenkins Installation'
java -jar /root/jenkins-cli.jar -s http://localhost:8080/ help || {
    printf '%s\n' 'Running jar for jenkins failed'
    exit 1
}

# Update jenkins plugins
printf '%s\n' 'Updating Jenkins Plugins'
UPDATE_LIST=$( java -jar /root/jenkins-cli.jar -s http://localhost:8080/ list-plugins | grep -e ')$' | awk '{ print $1 }' );
if [ ! -z "${UPDATE_LIST}" ]; then
    echo Updating Jenkins Plugins: ${UPDATE_LIST};
    java -jar /root/jenkins-cli.jar -s http://127.0.0.1:8080/ install-plugin ${UPDATE_LIST} ;
fi

# Install plugins for our Jenkins instance
printf '%s\n' 'Installing Jenkins Plugins'
for each in "
    sectioned-view
    workflow-aggregator
    join
    ws-cleanup
    git
    git-client
    github
    github-api
    dashboard-view
    parameterized-trigger
    run-condition
    build-with-parameters
    credentials
    plain-credentials
    ssh-agent
    scm-api
";
do
    java -jar /root/jenkins-cli.jar -s http://localhost:8080/ install-plugin $each ;
done

# Docker Permission Fix
# We need the jenkins user to have the docker group as its primary group in order to use docker as the jenkins user
usermod -a -G docker jenkins

# Change docker files to be owned by the docker group
#chown -R root:docker docker/

# Restarting Jenkins Server to install plugins and jobs
#java -jar /root/jenkins-cli.jar -s http://localhost:8080/ restart
service docker restart
service jenkins restart

until wget -O /root/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar; do
    echo "Trying to download jenkins-cli.jar attempt to check jenkins is backup and running."
    sleep 10
done

# @todo update terraform to 0.11+
# Installing Terraform
echo "Installing Terraform"
mkdir -p /opt/terraform
wget https://releases.hashicorp.com/terraform/0.10.3/terraform_0.10.3_linux_amd64.zip -O /opt/terraform/terraform_0.10.3_linux_amd64.zip
mv /usr/bin/terraform /usr/bin/terraform-old #failsafe
cd /opt/terraform ; unzip terraform_0.10.3_linux_amd64.zip
ln -s /opt/terraform/terraform /usr/bin/terraform

echo "# # # done # # #"
exit 0
