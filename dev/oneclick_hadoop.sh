#########################################################################
# File Name: oneclick_hadoop.sh
# Author: yijia
# mail: yijia2413@gmail.com
# Created Time: Wed May  6 14:40:34 2015
#########################################################################
#!/bin/bash

hadoop_url=http://apache.dataguru.cn/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz
hbase_url=http://apache.fayea.com/hbase/stable/hbase-1.0.1-bin.tar.gz

#java ssh 
user=$(whoami)

echo "installing java and ssh..."
if [ $(grep -c "Ubuntu" /etc/issue) -eq 1 ]
then
	sudo apt-get -y update > /dev/null
	sudo apt-get -y upgrade > /dev/null
	sudo apt-get -y install default-jdk default-jre ssh openssh-server rsync > /dev/null 2>&1
elif [ $(grep -c "Centos" /etc/issue) -eq 1 ]
then
	yum update -y > /dev/null 2>&1
	yum upgrade -y > /dev/null 2>&1
	yum install java-1.7.0-openjdk* rsync openssh-server -y > /dev/null 2>&1
fi

echo
echo "install java and ssh finished, now installing hadoop,downloading may take some time..."

#hadoop
mkdir -p /home/$user/fuckhadoop && cd /home/$user/fuckhadoop

if test -f hadoop-2.6.0.tar.gz
then
	echo "hadoop source file exists, copying..."
else
	wget $hadoop_url > /dev/null 2>&1
fi

if [ -d "/usr/local/hadoop" ]
then
	echo "/usr/local/hadoop/ exists, move it now..."
	sudo mv /usr/local/hadoop /usr/local/hadoop_bak
else
	echo "installing hadoop..."
fi

tar xvzf hadoop-2.6.0.tar.gz > /dev/null 
sudo mv hadoop-2.6.0 /usr/local/hadoop
sudo chmod -R 775 /usr/local/hadoop
sudo chown -R $user:$user /usr/local/hadoop

#prepare hadoop tmp dir
mkdir -p /usr/local/hadoop/tmp/dfs/{namenode,datanode}
mkdir -p /usr/local/hadoop/tmp/{hbase,zookeeper}

echo
echo "hadoop finished, now installing hbase..."
#hbase
if test -f hbase-1.0.1-bin.tar.gz
then
	echo "hbase source file exists, copying..."
else
	wget $hbase_url > /dev/null 2>&1
fi

if [ -d "/usr/local/hbase" ] 
then
	echo "/usr/local/hbase/ exists, move it now..."
	sudo mv /usr/local/hbase /usr/local/hbase_bak
else
	echo "installing hbase..."
fi

tar xvzf hbase-1.0.1-bin.tar.gz > /dev/null
sudo mv hbase-1.0.1 /usr/local/hbase
sudo chmod -R 755 /usr/local/hbase
sudo chown -R $user:$user /usr/local/hbase

echo
echo "now add ssh key gen.."
#ssh
if test -f /home/$user/.ssh/id_rsa
then
	echo "id_rsa exist, add to authorized_keys..."
else
	ssh-keygen -q -N "" -t rsa -f /home/$user/.ssh/id_rsa
fi

cat /home/$user/.ssh/id_rsa.pub >> /home/$user/.ssh/authorized_keys

echo
echo "now configuring..."

#config hadoop
#core-site.xml
#tmp dir
sed -i '/<conf/a \\t<property>\n\t\t<name>hadoop.tmp.dir</name>\n\t\t<value>/usr/local/hadoop/tmp</value>\n\t</property>\n' /usr/local/hadoop/etc/hadoop/core-site.xml

sed -i '/<conf/a \\t<property>\n\t\t<name>fs.defaultFS</name>\n\t\t<value>hdfs://localhost:9000</value>\n\t</property>\n' /usr/local/hadoop/etc/hadoop/core-site.xml

#hadoop-env.sh
sed -i 's/^export\ JAVA_HOME/#export\ JAVA_HOME/' /usr/local/hadoop/etc/hadoop/hadoop-env.sh && sed -i '/export\ JAVA_HOME/a export\ JAVA_HOME=\/usr\/lib\/jvm\/java-7-openjdk-amd64' /usr/local/hadoop/etc/hadoop/hadoop-env.sh

sed -i '/export\ JAVA_HOME/a export\ export\ HADOOP_PREFIX=\/usr\/local\/hadoop' /usr/local/hadoop/etc/hadoop/hadoop-env.sh

#hdfs-site.xml

sed -i '/<conf/a \\t<property>\n\t\t<name>dfs.namenode.name.dir</name>\n\t\t<value>/usr/local/hadoop/tmp/dfs/namenode</value>\n\t</property>\n'  /usr/local/hadoop/etc/hadoop/hdfs-site.xml 

sed -i '/<conf/a \\t<property>\n\t\t<name>dfs.datanode.data.dir</name>\n\t\t<value>/usr/local/hadoop/tmp/dfs/datanode</value>\n\t</property>\n'  /usr/local/hadoop/etc/hadoop/hdfs-site.xml 

sed -i '/<conf/a \\t<property>\n\t\t<name>dfs.replication</name>\n\t\t<value>1</value>\n\t</property>\n'  /usr/local/hadoop/etc/hadoop/hdfs-site.xml 

#mapred-site.xml
cat <<EOF >> /usr/local/hadoop/etc/hadoop/mapred-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
<property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
</property>
</configuration>
EOF

#yarn-site.xml
sed -i '/<conf/a \\t<property>\n\t\t<name>yarn.nodemanager.aux-services</name>\n\t\t<value>mapreduce_shuffle</value>\n\t</property>\n' /usr/local/hadoop/etc/hadoop/yarn-site.xml


#hbase-config
#hbase-site.xml
sed -i '/<conf/a \\t<property>\n\t\t<name>hbase.zookeeper.property.dataDir</name>\n\t\t<value>/usr/local/hadoop/tmp/zookeeper</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

sed -i '/<conf/a \\t<property>\n\t\t<name>hbase.zookeeper.quorum</name>\n\t\t<value>localhost</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

sed -i '/<conf/a \\t<property>\n\t\t<name>hbase.tmp.dir</name>\n\t\t<value>/usr/local/hadoop/tmp/hbase</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

sed -i '/<conf/a \\t<property>\n\t\t<name>hbase.cluster.distributed</name>\n\t\t<value>true</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

sed -i '/<conf/a \\t<property>\n\t\t<name>dfs.replication</name>\n\t\t<value>1</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

sed -i '/<conf/a \\t<property>\n\t\t<name>hbase.rootdir</name>\n\t\t<value>hdfs://localhost:9000/hbase</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

#hbase-env.sh
sed -i 's/^export\ JAVA_HOME/#export\ JAVA_HOME/' /usr/local/hbase/conf/hbase-env.sh && sed -i '/export\ JAVA_HOME/a export\ JAVA_HOME=\/usr\/lib\/jvm\/java-7-openjdk-amd64' /usr/local/hbase/conf/hbase-env.sh

sed -i '/export\ HBASE_CLASSPATH/a export\ HBASE_CLASSPATH=\/usr\/local\/hbase\/conf' /usr/local/hbase/conf/hbase-env.sh

#use zookeeper
sed -i '/export\ HBASE_MANAGES_ZK/a export\ HBASE_MANAGES_ZK=true' /usr/local/hbase/conf/hbase-env.sh


#profile
#HADOOP VARIABLES START
sudo sed -i '$a export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64 \
export HADOOP_HOME=/usr/local/hadoop \
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin \
export HADOOP_MAPRED_HOME=$HADOOP_HOME \
export HADOOP_COMMON_HOME=$HADOOP_HOME \
export HADOOP_HDFS_HOME=$HADOOP_HOME \
export YARN_HOME=$HADOOP_HOME \
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native \
export HADOOP_OPTS="-Djava.library.path-$HADOOP_HOME/lib" \
export HBASE_HOME=/usr/local/hbase \
export PATH=$PATH:$HBASE_HOME/bin \
export JRE_HOME=${JAVA_HOME}/jre \
export CLASSPATH=.${JAVA_HOME}/lib:${JRE_HOME}/lib:${HADOOP_HOME}/share/hadoop/common/lib:${HBASE_HOME}/lib \
' /etc/profile

source /etc/profile

echo "now all work done! enjoy.....^_^"
echo "try the following 4 commands:"
echo
echo "source /etc/profile"
echo "hdfs namenode -format"
echo "start-all.sh"
echo "start-hbase.sh"
