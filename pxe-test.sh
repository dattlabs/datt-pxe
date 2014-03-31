#!/bin/bash

PXECID=$(docker run -d --privileged datt/datt-pxe)
pipework br0 $PXECID 192.168.242.1/24
