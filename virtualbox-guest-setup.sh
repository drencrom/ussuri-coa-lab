#! /bin/bash

# Debug options to enable bash trace with output to file descriptor 1 (common output)
BASH_XTRACEFD="1"
PS4='$LINENO: '
set -x

export LC_TYPE="UTF-8"
export LANG="en-US.UTF-8"
export LC_ALL="C"

cat <<- EOF >> /etc/multipath.conf
blacklist {
    devnode "^(sda|sdb|sdc)[0-9]*"
}
EOF

# Set all Global Variables, defined in vars.sh
cp /vagrant/vars.sh /home/vagrant
cp /vagrant/install-openstack.sh /home/vagrant
cp /vagrant/configure-lab.sh /home/vagrant
mkdir -p /home/vagrant/labs
cp /vagrant/labs/* /home/vagrant/labs
source /home/vagrant/vars.sh

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y crudini

crudini --set /etc/default/grub "" GRUB_CMDLINE_LINUX '"net.ifnames=0 biosdevname=0"'
update-grub

cat <<- EOF > /etc/netplan/50-cloud-init.yaml
network:
    ethernets:
        $INTERNET_INTERFACE_NAME:
            dhcp4: true
        $PROVIDER_INTERFACE_NAME:
            dhcp4: false
        $MANAGEMENT_INTERFACE_NAME:
            addresses:
                - $CONTROLLER_IP/$CONTROLLER_NETMASK_LEN
            nameservers:
                addresses: [$CONTROLLER_NAMESERVERS]
    version: 2
    renderer: networkd
EOF

sed -i "s/scan_lvs = 0/scan_lvs = 1/" /etc/lvm/lvm.conf

pvcreate /dev/sdc
vgcreate os-data /dev/sdc
lvcreate -L 2G -n swift11 os-data
lvcreate -L 2G -n swift12 os-data
lvcreate -L 2G -n swift21 os-data
lvcreate -L 2G -n swift22 os-data
lvcreate -L 30G -n cinder-vols1 os-data
lvcreate -L 5G -n cinder-vols2 os-data

reboot
