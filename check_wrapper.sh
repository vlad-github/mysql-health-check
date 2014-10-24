#!/bin/bash

./check.sh "HOSTNAME" | mail -s "Health check for HOSTNAME" -b vlad@astellar.com root@localhost
