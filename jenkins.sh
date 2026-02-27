#!/bin/bash

distro=$(grep "^ID=" /etc/os-release | cut -d "=" -f2 | tr -d '"')

echo "Please enter the port number which is not used by any other application:"
read -t 30 port

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
    sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null

    sudo systemctl daemon-reload > /dev/null
    sudo systemctl start jenkins > /dev/null


elif [ "$distro" == "ubuntu" ]; then

    # FULL RESET
    sudo systemctl stop jenkins > /dev/null 2>&1
    sudo apt purge jenkins -y > /dev/null 2>&1
    sudo apt autoremove -y > /dev/null 2>&1
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

    
    sudo apt-get install fontconfig openjdk-25-jre -y > /dev/null
    sudo apt-get install jenkins -y > /dev/null

    # Modern systemd override for port (Ubuntu)
    sudo mkdir -p /etc/systemd/system/jenkins.service.d
    
    sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null <<EOF
    [Service]
    ExecStart=
    ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /usr/share/java/jenkins.war --webroot=/var/cache/jenkins/war --httpPort=$port
EOF
    
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
