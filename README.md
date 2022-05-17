1 Account
2 VPC

VPC AWS (10.0.0.1/16)
1 AZ
1 Private Subnet
    1 Route Table
1 CGW
1 VPN Gateway
1 VPC attached to VPN Gateway
1 VPN Connection
1 VPC SG

VPC On-Premise (172.21.0.1/16)
1 AZ
1 Public Subnet
1 Public Instance
    1 Public IP
    1 OpenSwan Installed
    1 Disabled IP source and destination check

1 Private Instance with Private IP
1 Route Table
    1 Route to VPC AWS