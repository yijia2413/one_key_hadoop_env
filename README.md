# one_key_to_fuck_hadoop
## Introduction
This is a simple script to set up hadoop and hbase pseudo environment.

*	OS: Ubuntu,Centos, Mac OS are all ok
*	Please run ./dev/oneclick_hadoop.sh with your __login account__, not the root account.
*	hadoop 2.6.0 + hbase 1.0.1
*	also, you can change the hadoop and hbase version for your own.


##Usage
For Vagrant users, just try:
	
	vagrant up
	vagrant provision

For other users, using ubuntu, centos or Mac os, try:

	./dev/oneclick_hadoop.sh
	
then, you can enjoy your hadoop and hbase environment.

after that, try:

	source /etc/profile (ubuntu/centos users)
	source ~/.bashrc (mac os users)
	hdfs dfs namenode -format
	start-all.sh
	start-hbase.sh
	jps (check the processes)
	
	
##Todo
*	run in vagrant with no root
*	mac need more test