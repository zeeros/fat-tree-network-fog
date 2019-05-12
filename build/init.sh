#!/bin/bash
CORE_NETS=2
EDGE_NETS=4
HOSTS=8
IMAGE="cirros-0.3.5-x86_64-disk"

#START PROJECT CREATION
#Create "fat_tree" project
openstack project create --domain default \
--description "Project for Cloud and Fog computing 2019" fat_tree &&
#Create the "eval" user
openstack user create --domain default \
--password-prompt eval &&
#Create the ~eval~ role
openstack role create eval &&
#Add the ~user~ role to the ~fat_tree~ project and ~eval~ user
openstack role add --project fat_tree --user eval eval
#END PROJECT CREATION

#SECURITY GROUPS
openstack security group create ICMP && \
openstack security group create SSH
#add rules
openstack security group rule create --description "enable ICMP" \
--protocol icmp \
--ingress ICMP
openstack security group rule create --description "enable SSH" \
	  --protocol tcp \
	  --dst-port 22:22 \
	  --ingress SSH

#START NETWORKS
#create the core networks
c=$((CORE_NETS-1))
while (( $c>=0 ))
do
    e=$((EDGE_NETS-1))
    openstack network create "core$c" && \
    while (( $e>=0 ))
    do
	#create the subnet
	openstack subnet create --network "core$c" \
		  --subnet-range "10.$((c+2)).$e.0/24" "subnet.c$c.e$e" && \
        #create port for the edge router
	    openstack port create --network "core$c" \
		      --fixed-ip subnet="subnet.c$c.e$e",ip-address="10.$((c+2)).$e.3" \
		      --security-group=default --security-group=ICMP --security-group=SSH "port.c$c.e$e"  && \
	e=$(( e-1 ))
    done
    c=$(( c-1 ))
done
#create the hosts networks
e=$((EDGE_NETS-1))
i=2
h=$((HOSTS-1))
while (( $e>=0 ))
do
    if((($e%2==0+1)))
    then
	i=$((i-1))
    fi
    j=$((e%2==1))
    openstack network create "net$e" && \
	openstack subnet create --network "net$e" \
		  --subnet-range "10.$i.$j.0/24" "subnet.e$e" && \
	#create ports for hosts
	openstack port create --network "net$e" \
		      --fixed-ip subnet="subnet.e$e",ip-address="10.$i.$j.4" \
		      --security-group=default --security-group=ICMP --security-group=SSH "port.h$h"  && \
	openstack port create --network "net$e" \
		      --fixed-ip subnet="subnet.e$e",ip-address="10.$i.$j.3" \
		      --security-group=default --security-group=ICMP --security-group=SSH "port.h$((h-1))"  && \
    h=$(( h-2 ))
    e=$(( e-1 ))
done
#END NETWORKS

#ROUTERS
#create the core routers
c=$((CORE_NETS-1))
while (( $c>=0 ))
do
    e=$((EDGE_NETS-1))
    #create routers
    openstack router create "router.c$c" && \
    while (( $e>=0 ))
    do
	#add subnet
	openstack router add subnet "router.c$c" "subnet.c$c.e$e" && \
	e=$(( e-1 ))
    done
    c=$(( c-1 ))
done
#create the hosts routers
e=$((EDGE_NETS-1))
while (( $e>=0 ))
do
    c=$((CORE_NETS-1))
    #create routers
    openstack router create "router.e$e" &&
    openstack router add subnet "router.e$e" "subnet.e$e" &&
    while (( $c>=0 ))
    do
	#add subnet
	openstack router add port "router.e$e" "port.c$c.e$e" &&
	c=$(( c-1 ))
    done
    e=$(( e-1 ))
done
#END ROUTERS

#create instances
h=$((HOSTS-1))
while (( $h>=0 ))
do
    openstack server create --flavor m1.tiny --image $IMAGE \
    --port "port.h$h" \
    --security-group ICMP --security-group SSH --security-group default \
    "host$h"
    h=$(( h-1 ))
done

#STATIC ROUTES
openstack router set \
	  --route destination=10.0.0.0/24,gateway=10.2.0.3 \
	  --route destination=10.0.1.0/24,gateway=10.2.1.3 \
	  --route destination=10.1.0.0/24,gateway=10.2.2.3 \
	  --route destination=10.1.1.0/24,gateway=10.2.3.3 \
	  router.c0 &&
openstack router set \
	  --route destination=10.0.0.0/24,gateway=10.3.0.3 \
	  --route destination=10.0.1.0/24,gateway=10.3.1.3 \
	  --route destination=10.1.0.0/24,gateway=10.3.2.3 \
	  --route destination=10.1.1.0/24,gateway=10.3.3.3 \
	  router.c1 &&
openstack router set \
	  --route destination=10.0.1.0/24,gateway=10.2.0.1 \
	  --route destination=10.1.0.0/24,gateway=10.2.0.1 \
	  --route destination=10.1.1.0/24,gateway=10.2.0.1 \
	  router.e0 &&
openstack router set \
	  --route destination=10.0.1.0/24,gateway=10.3.0.1 \
	  --route destination=10.1.0.0/24,gateway=10.3.0.1 \
	  --route destination=10.1.1.0/24,gateway=10.3.0.1 \
	  router.e0 &&
openstack router set \
	  --route destination=10.0.0.0/24,gateway=10.2.1.1 \
	  --route destination=10.1.0.0/24,gateway=10.2.1.1 \
	  --route destination=10.1.1.0/24,gateway=10.2.1.1 \
	  router.e1 &&
openstack router set \
	  --route destination=10.0.0.0/24,gateway=10.3.1.1 \
	  --route destination=10.1.0.0/24,gateway=10.3.1.1 \
	  --route destination=10.1.1.0/24,gateway=10.3.1.1 \
	  router.e1 &&
openstack router set \
	  --route destination=10.0.0.0/24,gateway=10.2.2.1 \
	  --route destination=10.0.1.0/24,gateway=10.2.2.1 \
	  --route destination=10.1.1.0/24,gateway=10.2.2.1 \
	  router.e2 &&
openstack router set \
	  --route destination=10.0.0.0/24,gateway=10.3.2.1 \
	  --route destination=10.0.1.0/24,gateway=10.3.2.1 \
	  --route destination=10.1.1.0/24,gateway=10.3.2.1 \
	  router.e2 &&
openstack router set \
	  --route destination=10.0.0.0/24,gateway=10.2.3.1 \
	  --route destination=10.0.1.0/24,gateway=10.2.3.1 \
	  --route destination=10.1.0.0/24,gateway=10.2.3.1 \
	  router.e3 &&
openstack router set \
	  --route destination=10.0.0.0/24,gateway=10.3.3.1 \
	  --route destination=10.0.1.0/24,gateway=10.3.3.1 \
	  --route destination=10.1.0.0/24,gateway=10.3.3.1 \
	  router.e3

