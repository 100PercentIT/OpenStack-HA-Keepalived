# OpenStack-HA-Keepalived
Configuration details and code for highly available instances using keepalived for IP address failover in OpenStack

### Requirements
To create an HA pair of instances you will need several things:
* Choose an image that you will use to create two instances and make a note of its ID - we've chosen Ubuntu for this example
* Choose the network that you want the instances to run on and make a note of its ID
* Make sure you have created an SSH key and make a note of its ID
* Know the size the instances need to be and choose the appropriate flavour
* The project_id, username and password for your OpenStack account

You will need to create security rules to allow the VRRP traffic between instances.  We do this by greating a new security group called vrrp

```
openstack 
```

### Instances
Now create the two instances
```
openstack server create --flavor m1.small --image [IMAGE_ID] \
  --nic net-id=[NETWORK_ID] --security-group default \
  --security-group vrrp --key-name [KEY_ID] vrrp-primary

openstack server create --flavor m1.small --image [IMAGE_ID] \
  --nic net-id=[NETWORK_ID] --security-group default \
  --security-group vrrp --key-name [KEY_ID] vrrp-secondary
```
You can verify that these instances were created using:
```
openstack server list
```

### Public IP addresses
We will use three public IP addresses for this example - one for each of the instances and one that is the highly available IP which will be assigned to the primary instance when it is working with the ability to failover to the secondary instance.
```
openstack ip floating create public
```

### Configure the instances
Install keepalived, python and the neutron client on each instance:
```
apt-get install keepalived python2.7 python-neutronclient
```

Copy the failover-primary-to-secondary.sh and failover-secondary-to-primary.sh scripts into /etc/keepalived/ then edit both files to set the instance IDs and make the scripts executable:
```
chmod +x /etc/keepalived/failover-primary-to-secondary.sh
chmod +x /etc/keepalived/failover-secondary-to-primary.sh
```
Copy the primary-keepalived.conf file to /etc/keepalived.conf on the primary instance and secondary-keepalived.conf file to /etc/keepalived.conf on the secondary instance then edit /etc/keepalived.conf on both instances to set the network interface name.

Setup authentication for the failover scripts to run by making a directory to hold the clouds.yaml authentiction file:
```
mkdir -p /root/.config/openstack
```
Copy the clouds.yaml file to to /root/.config/openstack/clouds.yaml and edit the file to set the project_id, username and password for your account.

### Test it!
The system should now work and the shared public IP address should failover from the primary to the secondary instance when the primary has a fault.  When the primary is restored the IP should be handed back 30 seconds after the primary is stable (to give enough time for other services to start - you can change this delay be editing the preempt_delay in /etc/keepalived.conf on the secondary instance.

We will demonstrate this by installing Apache to serve different content on the two instances:

```
apt-get install apache2
```

Edit the /var/www/index.html file so that we can distinguish between the instances:

On the primary run `echo "Primary" > /var/www/index.html`
On the secondary run `echo "Secondary" > /var/www/index.html`

Now put the shared public IP address into a web browser on your local computer - you should see a simple page saying "Primary"

If you now stop the primary instance and reload your web browser you should see "Secondary." Restarting the primary instance will return the IP address to it.

Congratulations - you now have a highly available public IP address.  The next step is to setup the service (such as HAProxy) that you want to make highly available and remove Apache if you set that up to test.
