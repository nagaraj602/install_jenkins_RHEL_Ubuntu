#!/bin/bash

distro=$(cat /etc/os-release | grep "^ID=" | cut -d "=" -f2 | sed 's/"//g')
echo "Please enter the port number which is not used by any other application:"
read port


# Check if port is a valid number
if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo "Invalid port number!"
    exit 1
fi

# Check if port is already in use
if ss -tuln | grep -q ":$port "; then
    echo "Port $port is already in use. Please run the script again with a free port."
    exit 1
fi


echo "Installing Jenkins on $distro"

if [ $distro == "rhel" ]; then
    sudo yum update -y > /dev/null
    sudo yum install wget -y > /dev/null

    sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/rpm-stable/jenkins.repo
    
    sudo yum upgrade -y > /dev/null
    sudo yum install fontconfig java-25-openjdk -y > /dev/null
    
    sudo yum install jenkins -y > /dev/null
    
    sudo systemctl daemon-reload > /dev/null
    sudo systemctl start jenkins > /dev/null
    
    
elif [ $distro == "ubuntu" ]; then
    
    sudo apt install wget -y > /dev/null

    sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key > /dev/null
    
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    sudo apt update-y > /dev/null
    sudo apt install fontconfig openjdk-25-jre -y > /dev/null
    
    sudo apt install jenkins -y > /dev/null
    
    sudo systemctl daemon-reload > /dev/null
    sudo systemctl start jenkins > /dev/null


else
    echo "Unsupported Distribution - Only RHEL and Ubuntu are supported by this Script!!!!"
fi

    # Update Jenkins port
    if [ "$distro" == "rhel" ]; then
        sudo sed -i "s/^JENKINS_PORT=.*/JENKINS_PORT=\"$port\"/" /etc/sysconfig/jenkins
    elif [ "$distro" == "ubuntu" ]; then
        sudo sed -i "s/^HTTP_PORT=.*/HTTP_PORT=$port/" /etc/default/jenkins
    fi

echo "Access Jenkins at $(curl -s ifconfig.me):$port"
