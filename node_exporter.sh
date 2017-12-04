#!/usr/bin/env bash

echo "This shell script will perform following activities:"
echo "  - Download node_exporter from 'https://prometheus.io/download/#node_exporter'"
echo "     and save it as an executable at '/usr/local/bin/'"
echo "  - Create a service file for service 'node_exporter' and start the service."
echo "Please enter 'y' to confirm the changes..."

read ans

prerequisites() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script requires elevated permissions, therefore sudo access will be requested."
        if hash sudo 2> /dev/null; then
            SUDO=$(whereis sudo|cut -d" " -f2)
        else
            echo "Sudo not found. Please re-run the script as root."
            exit 127;
        fi
    fi
    
    if hash curl 2> /dev/null; then
        DOWNLOADER='curl -L';
        DOWNLOAD_OPTION='-o';
    elif hash wget 2> /dev/null; then
        DOWNLOADER='wget';
        DOWNLOAD_OPTION='-O';
    else
        echo "Curl or Wget not found. Please install curl or wget and re-run the script."
        exit 127;
    fi

    if ! hash tar 2> /dev/null; then
        echo "Tar not found. Please install tar and re-run the script."
        exit 127;
    fi
}

get_node() {
    cd /tmp/
    $DOWNLOADER https://github.com/prometheus/node_exporter/releases/download/v0.15.1/node_exporter-0.15.1.linux-amd64.tar.gz $DOWNLOAD_OPTION /tmp/node_exporter.tar.gz    
    tar -xzf /tmp/node_exporter.tar.gz
    $SUDO cp node_exporter-0.15.1.linux-amd64/node_exporter /usr/local/bin
    rm /tmp/node_exporter.tar.gz
    rm -rf /tmp/node_exporter-0.15.1.linux-amd64/
}

service_status () {
    if [ "$?" -eq "0" ]; then
        echo "Setup Complete. Your node metrics are now available on port 9100."
        exit 0;
    else
        echo "Something bad happended. Exiting..."
        $SUDO systemctl status node_exporter
        exit 1;            
    fi
}

start_node() {
    echo " Enter 'systemd' to create systemd service file or 'init' to create sysvinit script. "
    read filetype
    if [ "$filetype" == "init" ]; then
        $SUDO $DOWNLOADER https://raw.githubusercontent.com/arush-sal/prom-stack/master/node_exporter.init.d \
            $DOWNLOAD_OPTION /etc/init.d/node_exporter
        $SUDO chmod +x /etc/init.d/node_exporter
        $SUDO service node_exporter start
        service_status
    elif [ "$filetype" == "systemd" ]; then
        $SUDO $DOWNLOADER https://raw.githubusercontent.com/arush-sal/prom-stack/master/node_exporter.service.systemd \
            $DOWNLOAD_OPTION /etc/systemd/system/node_exporter.service
        $SUDO systemctl daemon-reload
        $SUDO systemctl enable node_exporter
        $SUDO systemctl start node_exporter
        service_status
    else
        echo "Sorry please try again."
        exit 1;
    fi
}

if [ "$ans" == "y" ] || [ "$ans" == "Y" ]; then
    echo -e "\nThank you for your confirmation. Let's roll..."
    prerequisites
    get_node
    start_node
else
    exit 126;
fi
