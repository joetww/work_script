#!/bin/bash

## windows搭配cygwin

MyIP="60.251.113.98 220.132.147.161 125.227.175.211"

## 整批IP增加的方法
netsh advfirewall firewall add rule name="GAMEMAG_IP_ALL" dir=in protocol=any action=allow remoteip="$(echo ${MyIP} | xargs | tr ' ' ',')"
