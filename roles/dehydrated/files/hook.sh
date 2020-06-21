#!/bin/bash

if [ ${1} == "deploy_cert" ]; then
    echo " + Hook: Reloading nginx config..."
    /etc/init.d/nginx reload
else
    echo " + Hook: Nothing to do..."
fi

