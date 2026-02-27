#!/bin/bash

distro=$(cat /etc/os-release | grep "^ID=" | cut -d "=" -f2 | sed 's/"//g')

echo
echo
echo
echo "Please enter the port number which is not used by any other application:"
read -t 15 port

# Function to check if port is free
is_port_free() {
    ! ss -tuln | grep -q ":$1 "
}

# If user did NOT enter anything (timeout case)
if [ -z "$port" ]; then
    port=8080
    while ! is_port_free "$port"; do
        port=$((port+1))
    done
else
    # If user entered a value, validate and re-ask if invalid/busy
    while ! [[ "$port" =~ ^[0-9]+$ ]] || \
          [ "$port" -lt 1 ] || \
          [ "$port" -gt 65535 ] || \
          ! is_port_free "$port"
    do
        echo "Invalid or busy port. Please enter another port:"
        read port
    done
fi


echo
echo "Installing Jenkins on $distro"

if [ "$distro" == "rhel" ]; then

    # FULL RESET
    sudo systemctl stop jenkins > /dev/null 2>&1
    sudo yum remove jenkins -y > /dev/null 2>&1
    sudo rm -rf /var/lib/jenkins \
                /var/log/jenkins \
                /etc/systemd/system/jenkins.service.d \
                /etc/yum.repos.d/jenkins.repo \
                /usr/lib/systemd/system/jenkins.service \
                /etc/sysconfig/jenkins > /dev/null 2>&1
    sudo systemctl daemon-reload > /dev/null 2>&1

    sudo yum update -y > /dev/null
    sudo yum install wget -y > /dev/null

    sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/rpm-stable/jenkins.repo > /dev/null 2>&1

    sudo yum upgrade -y > /dev/null
    sudo yum install fontconfig java-25-openjdk -y > /dev/null
    sudo yum install jenkins -y > /dev/null

    # Modern systemd override for port
    sudo mkdir -p /etc/systemd/system/jenkins.service.d
    echo -e "[Service]\nEnvironment=\"JENKINS_PORT=$port\"" | \
    sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null 2>&1


    sudo systemctl daemon-reload > /dev/null
    sudo systemctl start jenkins > /dev/null


elif [ "$distro" == "ubuntu" ]; then

    # FULL RESET
    sudo systemctl stop jenkins > /dev/null 2>&1
    sudo NEEDRESTART_MODE=a apt-get purge jenkins -y & > /dev/null 2>&1
    sudo NEEDRESTART_MODE=a apt-get autoremove -y & > /dev/null 2>&1
    sudo rm -rf /var/lib/jenkins \
                /var/log/jenkins \
                /etc/systemd/system/jenkins.service.d \
                /etc/apt/sources.list.d/jenkins.list \
                /etc/default/jenkins > /dev/null 2>&1
    sudo systemctl daemon-reload > /dev/null 2>&1

    sudo apt-get update -y > /dev/null
    sudo apt-get install wget -y > /dev/null

    sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key > /dev/null 2>&1

    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/" | \
    sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

    sudo apt-get update -y > /dev/null
    sudo apt-get install fontconfig openjdk-25-jre -y > /dev/null
    sudo apt-get install jenkins -y > /dev/null

   sudo sed -i "s/^HTTP_PORT=.*/HTTP_PORT=$port/" /etc/default/jenkins
    sudo systemctl restart jenkins > /dev/null
    
    sudo systemctl daemon-reload > /dev/null
    sudo systemctl start jenkins > /dev/null

else
    echo "Unsupported Distribution - Only RHEL and Ubuntu are supported by this Script!!!!"
    exit 1
fi

echo "Access Jenkins at http://$(curl -s ifconfig.me):$port"


initialAdminPassword=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

echo
echo "Here is the Initial Admin Password: $initialAdminPassword"
echo






echo
echo "Do you want to exit from this script? Or perform another operation?"
echo "1) Exit"
echo "2) Install Tomcat"
echo "3) Install Maven"
echo

read -p "Enter your choice [1-3]: " choice

case $choice in
    1)
        echo "Exiting script..."
        exit 0
        ;;
    2)
        echo "Installing Tomcat..."
        cd
        sudo yum install git -y > /dev/null 2>&1
        rm -rf install_tomcat_RHEL_Ubuntu
        git clone https://github.com/nagaraj602/install_tomcat_RHEL_Ubuntu.git > /dev/null 2>&1
        cd install_tomcat_RHEL_Ubuntu || exit
        bash tomcat.sh
        ;;
    3)
        echo "Installing Maven..."
        cd
        sudo yum install git -y > /dev/null 2>&1
        rm -rf install_maven_RHEL_Ubuntu
        git clone https://github.com/nagaraj602/install_maven_RHEL_Ubuntu.git > /dev/null 2>&1
        cd install_maven_RHEL_Ubuntu || exit
        bash maven.sh
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac
