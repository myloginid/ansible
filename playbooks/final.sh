#!/bin/sh

HOSTS_FILE="../../inventory/hosts"
SSH_PASS="sshpass-1.05-1.el6.x86_64.rpm"

ansible --version
if [ $? -ne 0 ]; then
yum install python
yum install ansible
yum upgrade ansible
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/${SSH_PASS}
rpm -Uvh ${SSH_PASS}
rm -f ${SSH_PASS}
fi


### Creating the ssh keys if not present. Make sure you go through the interactive process of ssh keys generation
if [ ! -f ~/.ssh/id_rsa.pub ]; then
ssh-keygen -t rsa
fi

echo "Is the script going to run on new set of machines or exisiting machines. Please specify yes or no"
read ANSWER
if [ ${ANSWER} == "yes" ]; then
echo "Please enter the root password for the new machines in the cluster"
read PASSWORD

#Reading all the new host names form new_hosts and establishing the passwordless ssh connection from current machine to those, so ansible can run via ssh
for IP in `cat ../../inventory/hosts | grep -v "\["`
do
if [ -z ${IP} ]; then
echo ""
fi
sshpass -p ${PASSWORD} ssh-copy-id root@${IP} -p 22
done
fi

for playbook in preinstall.yml mysqlsetup.yml clouderasetup.yml
do
echo ${playbook}
ansible-playbook  ${playbook} -i ${HOSTS_FILE}
done

#echo "Running pre-check on all machines"
#ansible-playbook -vvv preinstall.yml -i ${HOSTS_FILE}
#echo "Running mysql setup on cloudera hosts"
#ansible-playbook -vvv mysqlsetup.yml -i ${HOSTS_FILE}
#echo "Running final cloudera cluster"
#ansible-playbook -vvv clouderasetup.yml  -i ${HOSTS_FILE} 

#echo " checking cloudera-scm-server status"
for IP in `cat ../../inventory/hosts | grep -v "\["`
do
if [ -z ${IP} ]; then
echo ""
fi
echo "checkign the cloudera service status on ${IP}"
ssh root@${IP} "service cloudera-scm-server status"
done

