FROM redhat/ubi8:latest

# Install dependencies
RUN yum localinstall https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rp
RUN subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
RUN yum install yum-plugin-copr

# Add the OpenVPN repository
RUN yum copr enable dsommers/openvpn3

# Install OpenVPN Connector setup tool
RUN yum install python3-openvpn-connector-setup

# Enable IP forwarding
COPY << EOF >> /etc/sysctl.conf \n\
    net.ipv4.ip_forward=1 \n\
    net.ipv6.conf.all.forwarding=1 \n\
    EOF \n
RUN sysctl -p

# Configure NAT
RUN for sfx in  \
        `--add-masquerade` \
        `--direct --add-rule ipv4 nat POSTROUTING 0 -j MASQUERADE` \
        `--direct --add-rule ipv4 filter FORWARD 0 -j ACCEPT` \
        `--direct --add-rule ipv6 nat POSTROUTING 0 -j MASQUERADE` \
        `--direct --add-rule ipv6 filter FORWARD 0 -j ACCEPT`; \
    do firewall-cmd --permanent $sfx done
RUN systemctl restart firewalld

# Run openvpn-connector-setup to install ovpn profile and connect to VPN.
# You will be asked to enter setup token. You can get setup token from Linux
# Connector configuration page in OpenVPN Cloud Portal
RUN openvpn-connector-setup
