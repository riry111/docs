#!/bin/bash

if [[ ! -d /root/rails/dengonban ]];then
	/usr/local/bin/create_app.sh
fi

cd /root/rails/dengonban

rails s -e production -p 80 -d

while [[ true ]];do
	/bin/bash
done

