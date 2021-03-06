#########################################################################
# File Name: oneclick_hadoop.sh
# Author: yijia
# mail: yijia2413@gmail.com
# Created Time: Wed May  6 14:40:34 2015
#########################################################################
#!/bin/bash

set -o nounset
set -o errexit

#set sed for linux or mac
darwin=false;
case "`uname`" in
  Darwin*) darwin=true ;;
esac

sedi="sed -i"

#set your own hadoop and hbase here~
hadoop_version=hadoop-2.6.0
hbase_version=hbase-1.0.1
hadoop_tar=hadoop-2.6.0.tar.gz
hbase_tar=hbase-1.0.1-bin.tar.gz
hadoop_url=http://apache.dataguru.cn/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz
hbase_url=http://apache.fayea.com/hbase/stable/hbase-1.0.1-bin.tar.gz

#hbase_url=https://archive.apache.org/dist/hbase/hbase-1.0.0/hbase-1.0.0-bin.tar.gz
#hbase_url=http://mirror.symnds.com/software/Apache/hbase/0.98.12.1/hbase-0.98.12.1-hadoop2-bin.tar.gz
#hadoop_url=http://mirror.sdunix.com/apache/hadoop/common/hadoop-2.7.0/hadoop-2.7.0.tar.gz

#java ssh 
user=$(whoami)

echo "installing java and ssh..."

if [ $(grep -c "Ubuntu" /etc/issue) -eq 1 ]
then
	sudo apt-get -y update  2>&1
	sudo apt-get -y upgrade  2>&1
	sudo apt-get -y install default-jdk default-jre ssh openssh-server rsync > /dev/null 2>&1
elif [ $(grep -c "Centos" /etc/issue) -eq 1 ]
then
	yum update -y 2>&1
	yum upgrade -y 2>&1
	yum install java-1.7.0-openjdk* rsync openssh-server -y 2>&1
elif $darwin
then
	if [ $(brew -v | grep Homebrew | wc -l) -eq 1 ]
	then
		echo "brew installed"
	else
		ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" 2>&1
	fi

	if [ $(which java | grep jdk | wc -l) -eq 1 ]
	then
		echo "java installed"
	else
		echo "installing java, please wait..."
		brew cask install caskroom/versions/java7 2>&1
	fi
	
	if [ $(wget -V | head -1 | grep Wget | wc -l) -eq 1 ]
	then
		echo "wget installed"
	else
		echo "installing wget"
		brew install wget 2>&1
	fi

	if [ $(sed --version | head -1 | grep GNU | wc -l) -eq 1 ]
	then
		echo "GNU sed installed"
	else
		brew install gnu-sed
		ln -s /usr/local/bin/gsed /usr/local/bin/sed
	fi
fi

echo
echo "install java and ssh finished, now installing hadoop,downloading may take some time..."

#hadoop
mkdir -p ~/fuckhadoop && cd ~/fuckhadoop

if test -f $hadoop_tar
then
	echo "hadoop source file exists, copying..."
else
	wget $hadoop_url 2>&1
fi

if [ -d "/usr/local/hadoop" ]
then
	echo "/usr/local/hadoop/ exists, move it now..."
	sudo mv /usr/local/hadoop /usr/local/hadoop_bak
else
	echo "installing hadoop..."
fi

tar xvzf $hadoop_tar > /dev/null 
sudo mv $hadoop_version /usr/local/hadoop
sudo chmod -R 775 /usr/local/hadoop
if $darwin
then
	sudo chown -R $user:staff /usr/local/hadoop
else
	sudo chown -R $user:$user /usr/local/hadoop
fi

#prepare hadoop tmp dir
mkdir -p /usr/local/hadoop/tmp/dfs/{namenode,datanode}
mkdir -p /usr/local/hadoop/tmp/{hbase,zookeeper}

echo
echo "hadoop finished, now installing hbase..."

#hbase
if test -f $hbase_tar
then
	echo "hbase source file exists, copying..."
else
	wget $hbase_url 2>&1
fi

if [ -d "/usr/local/hbase" ] 
then
	echo "/usr/local/hbase/ exists, move it now..."
	sudo mv /usr/local/hbase /usr/local/hbase_bak
else
	echo "installing hbase..."
fi

tar xvzf $hbase_tar > /dev/null
sudo mv $hbase_version /usr/local/hbase
sudo chmod -R 755 /usr/local/hbase
if $darwin
then
	sudo chown -R $user:staff /usr/local/hbase
else
	sudo chown -R $user:$user /usr/local/hbase
fi

echo
echo "now add ssh key gen.."
#ssh
if test -f ~/.ssh/id_rsa
then
	echo "id_rsa exist, add to authorized_keys..."
else
	ssh-keygen -q -N "" -t rsa -f ~/.ssh/id_rsa
fi

cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

echo
echo "now configuring..."

#config hadoop
#core-site.xml
#tmp dir
$sedi '/<conf/a \\t<property>\n\t\t<name>hadoop.tmp.dir</name>\n\t\t<value>/usr/local/hadoop/tmp</value>\n\t</property>\n' /usr/local/hadoop/etc/hadoop/core-site.xml

$sedi '/<conf/a \\t<property>\n\t\t<name>fs.defaultFS</name>\n\t\t<value>hdfs://localhost:9000</value>\n\t</property>\n' /usr/local/hadoop/etc/hadoop/core-site.xml

#hadoop-env.sh
if $darwin
then
	$sedi 's/^export\ JAVA_HOME/#export\ JAVA_HOME/' /usr/local/hadoop/etc/hadoop/hadoop-env.sh
	$sedi '/export\ JAVA_HOME/a export\ JAVA_HOME=\`/usr\/libexec\/java_home`' /usr/local/hadoop/etc/hadoop/hadoop-env.sh
else
	$sedi 's/^export\ JAVA_HOME/#export\ JAVA_HOME/' /usr/local/hadoop/etc/hadoop/hadoop-env.sh 
	$sedi '/export\ JAVA_HOME/a export\ JAVA_HOME=\/usr\/lib\/jvm\/java-7-openjdk-amd64' /usr/local/hadoop/etc/hadoop/hadoop-env.sh
fi

$sedi '/export\ JAVA_HOME/a export\ export\ HADOOP_PREFIX=\/usr\/local\/hadoop' /usr/local/hadoop/etc/hadoop/hadoop-env.sh

#hdfs-site.xml

$sedi '/<conf/a \\t<property>\n\t\t<name>dfs.namenode.name.dir</name>\n\t\t<value>/usr/local/hadoop/tmp/dfs/namenode</value>\n\t</property>\n'  /usr/local/hadoop/etc/hadoop/hdfs-site.xml 

$sedi '/<conf/a \\t<property>\n\t\t<name>dfs.datanode.data.dir</name>\n\t\t<value>/usr/local/hadoop/tmp/dfs/datanode</value>\n\t</property>\n'  /usr/local/hadoop/etc/hadoop/hdfs-site.xml 

$sedi '/<conf/a \\t<property>\n\t\t<name>dfs.replication</name>\n\t\t<value>1</value>\n\t</property>\n'  /usr/local/hadoop/etc/hadoop/hdfs-site.xml 

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
$sedi '/<conf/a \\t<property>\n\t\t<name>yarn.nodemanager.aux-services</name>\n\t\t<value>mapreduce_shuffle</value>\n\t</property>\n' /usr/local/hadoop/etc/hadoop/yarn-site.xml


#hbase-config
#hbase-site.xml
$sedi '/<conf/a \\t<property>\n\t\t<name>hbase.zookeeper.property.dataDir</name>\n\t\t<value>/usr/local/hadoop/tmp/zookeeper</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

$sedi '/<conf/a \\t<property>\n\t\t<name>hbase.zookeeper.quorum</name>\n\t\t<value>localhost</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

$sedi '/<conf/a \\t<property>\n\t\t<name>hbase.tmp.dir</name>\n\t\t<value>/usr/local/hadoop/tmp/hbase</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

$sedi '/<conf/a \\t<property>\n\t\t<name>hbase.cluster.distributed</name>\n\t\t<value>true</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

$sedi '/<conf/a \\t<property>\n\t\t<name>dfs.replication</name>\n\t\t<value>1</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

$sedi '/<conf/a \\t<property>\n\t\t<name>hbase.rootdir</name>\n\t\t<value>hdfs://localhost:9000/hbase</value>\n\t</property>\n' /usr/local/hbase/conf/hbase-site.xml

#hbase-env.sh
if $darwin
then
	$sedi 's/^export\ JAVA_HOME/#export\ JAVA_HOME/' /usr/local/hbase/conf/hbase-env.sh 
	$sedi '/export\ JAVA_HOME/a export\ JAVA_HOME=\`/usr\/libexec\/java_home`' /usr/local/hbase/conf/hbase-env.sh
else
	$sedi 's/^export\ JAVA_HOME/#export\ JAVA_HOME/' /usr/local/hbase/conf/hbase-env.sh 
	$sedi '/export\ JAVA_HOME/a export\ JAVA_HOME=\/usr\/lib\/jvm\/java-7-openjdk-amd64' /usr/local/hbase/conf/hbase-env.sh
fi

#$sedi '/export\ HBASE_CLASSPATH/a export\ HBASE_CLASSPATH=\/usr\/local\/hbase\/conf' /usr/local/hbase/conf/hbase-env.sh

#use zookeeper
$sedi '/export\ HBASE_MANAGES_ZK/a export\ HBASE_MANAGES_ZK=true' /usr/local/hbase/conf/hbase-env.sh


#profile
#HADOOP VARIABLES START
if $darwin
then
	sudo $sedi '$a export JAVA_HOME=`/usr/libexec/java_home` \
export JRE_HOME=$JAVA_HOME/jre \
export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH  \
export PATH=.:$JAVA_HOME/bin:$JRE_HOME/bin:$PATH \
export HADOOP_HOME=/usr/local/hadoop \
export PATH=$PATH:$HADOOP_HOME/bin \
export PATH=$PATH:$HADOOP_HOME/sbin \
export HADOOP_MAPRED_HOME=$HADOOP_HOME \
export HADOOP_COMMON_HOME=$HADOOP_HOME \
export HADOOP_HDFS_HOME=$HADOOP_HOME \
export HADOOP_YARN_HOME=$HADOOP_HOME \
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native \
export HBASE_HOME=/usr/local/hbase \
export PATH=$PATH:$HBASE_HOME/bin \
export CLASSPATH=$PATH:$HBASE_HOME/lib \
' ~/.bashrc

else
	sudo $sedi '$a export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64 \
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
export CLASSPATH=.${JAVA_HOME}/lib:${JRE_HOME}/lib:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:${HADOOP_HOME}/share/hadoop/common/lib:${HBASE_HOME}/lib \
' /etc/profile
fi

echo "now all work done! enjoy.....^_^"
echo "try the following 4 commands:"
echo
echo "1. source /etc/profile (ubuntu/centos)"
echo "1. source ~/.bashrc (mac os)"
echo "2. hdfs namenode -format"
echo "3. start-all.sh"
echo "4. start-hbase.sh"
