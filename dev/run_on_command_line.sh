#########################################################################
# File Name: run_on_command_line.sh
# Author: yijia
# mail: yijia2413@gmail.com
# Created Time: Sun May 31 11:11:58 2015
#########################################################################

#thanks for zwlin

if [ $# -lt 1 ] ; then
   echo "Usage: $0 <java file name>";
   exit 
fi
echo $#

#check hadoop_home
if [ -d "$HADOOP_HOME" ] ; then
	echo "HADOOP_HOME : $HADOOP_HOME"
else 
	echo "you should set HADOOP_HOME first !"
	exit
fi

#check hbase_home
if [ -d "$HBASE_HOME" ] ; then
	echo "HBASE_HOME : $HBASE_HOME"
else
	echo "you should set HBASE_HOME first !"
	exit
fi

#add hadoop libs
for i in $HADOOP_HOME/share/hadoop/* ; do
	for j in $i/*.jar ; do
		export CLASSPATH=$CLASSPATH:$j;
	done;
	for j in $i/lib/*.jar ; do 
		export CLASSPATH=$CLASSPATH:$j;
	done;
done;

#add hbase libs
for i in $HBASE_HOME/lib/*.jar ; do 
	export CLASSPATH=$CLASSPATH:$i;
done;

#echo $CLASSPATH

#set your command below...

#compile
javac YourProgram.java

#make jar files
jar cfm YourProgram.jar YourProgram-manifest.txt YourProgram*.class

#run with jar
hadoop jar ./YourProgram.jar <argv0> <argv1> ...

