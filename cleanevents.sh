#!/bin/bash
phionctrl box block event
sleep 2
rm -f /phion0/event/event*
rm -f /opt/phion/preserve/eventd-buffer*
phionctrl box start event
