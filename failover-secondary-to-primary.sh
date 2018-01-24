#!/bin/bash
# failover-secondary-to-primary.sh
neutron --os-cloud 100percentit floatingip-associate [floatingip-ID] [vrrp-secondary port ID]
neutron --os-cloud 100percentit floatingip-disassociate [floatingip-ID] [vrrp-primary port ID]
