# How to use this role

0) Get a Domain- and Hostname with a functioning DNS entry, 
   i.e greenlight.my.domain

1) Change the postgres password in default/main.yml

2) Get an empty debian 10 host with root access

3) Run ansible:

ansible-playbook -i "greenlight.my.domain," greenlight-standalone.yml

- Hostname and certificate will be set from inventory hostname 
given in -i argument
- BBB Backend URI and Secret must be set in the playbook/vault

4) Log in to your server, check and configure the GL environment file in 
/srv/docker/greenlight/.env

5) Start Greenlight

6) Create Accounts (https://docs.bigbluebutton.org/greenlight/gl-admin.html#creating-an-administrator-account)



