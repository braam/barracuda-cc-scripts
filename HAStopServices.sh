#!/bin/bash

#Run this on the firewalls that are currently active, so failover will take place to the Standby firewall.

SERVICENAME=$(/opt/phion/bin/phionctrl server show | head -n1 | cut -f1 -d$'\t')

#block service, so failover will happen.
/opt/phion/bin/phionctrl server block $SERVICENAME

