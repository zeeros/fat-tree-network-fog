#!/bin/bash
IMAGE="cirros-0.3.5-x86_64-disk"
openstack security group create ICMP
openstack security group rule create --description "enable ICMP" \
	  --protocol icmp \
	  --ingress ICMP

openstack network create "netA"
openstack subnet create --network "netA" \
	  --subnet-range "10.0.0.0/24" "subnetA"
openstack port create --network "netA" \
		      --fixed-ip subnet="subnetA",ip-address="10.0.0.3" \
		      --security-group=default --security-group=ICMP "portA"
openstack network create "net0"
openstack subnet create --network "net0" \
	  --subnet-range "10.2.0.0/24" "subnet0"
openstack port create --network "net0" \
		      --fixed-ip subnet="subnet0",ip-address="10.2.0.3" \
		      --security-group=default --security-group=ICMP "port0"
openstack network create "net1"
openstack subnet create --network "net1" \
	  --subnet-range "10.3.0.0/24" "subnet1"
openstack port create --network "net1" \
		      --fixed-ip subnet="subnet1",ip-address="10.3.0.3" \
		      --security-group=default --security-group=ICMP "port1"
openstack network create "net2"
openstack subnet create --network "net2" \
	  --subnet-range "10.2.1.0/24" "subnet2"
openstack port create --network "net2" \
		      --fixed-ip subnet="subnet2",ip-address="10.2.1.3" \
		      --security-group=default --security-group=ICMP "port2"
openstack network create "net3"
openstack subnet create --network "net3" \
	  --subnet-range "10.3.1.0/24" "subnet3"
openstack port create --network "net3" \
		      --fixed-ip subnet="subnet3",ip-address="10.3.1.3" \
		      --security-group=default --security-group=ICMP "port3"
openstack network create "netB"
openstack subnet create --network "netB" \
	  --subnet-range "10.0.1.0/24" "subnetB"
openstack port create --network "netB" \
		      --fixed-ip subnet="subnetB",ip-address="10.0.1.3" \
		      --security-group=default --security-group=ICMP "portB"

openstack server create --flavor m1.tiny --image $IMAGE \
    --port "portA" \
    --security-group ICMP --security-group default \
    "hostA"
openstack server create --flavor m1.tiny --image $IMAGE \
    --port "portB" \
    --security-group ICMP --security-group default \
    "hostB"

openstack router create "RA"
openstack router add subnet RA subnetA
openstack router add port RA port0
openstack router add port RA port1

openstack router create "RB"
openstack router add subnet RB subnetB
openstack router add port RB port2
openstack router add port RB port3

openstack router create "R0"
openstack router add subnet R0 subnet0
openstack router add subnet R0 subnet2

openstack router create "R1"
openstack router add subnet R1 subnet1
openstack router add subnet R1 subnet3

openstack router set \
	  --route destination=10.0.1.0/24,gateway=10.2.0.1 \
	  --route destination=10.0.1.0/24,gateway=10.3.0.1 \
	  RA

openstack router set \
	  --route destination=10.0.0.0/24,gateway=10.2.0.3 \
	  --route destination=10.0.1.0/24,gateway=10.2.1.3 \
	  R0

openstack router set \
	  --route destination=10.0.0.0/24,gateway=10.3.0.3 \
	  --route destination=10.0.1.0/24,gateway=10.3.1.3 \
	  R1

openstack router set \
	  --route destination=10.0.0.0/24,gateway=10.2.1.1 \
	  --route destination=10.0.0.0/24,gateway=10.3.1.1 \
	  RB
