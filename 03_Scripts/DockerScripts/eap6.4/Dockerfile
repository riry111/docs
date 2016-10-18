##################################################
#                                                #
# Creates a base rhel7  image with JBoss EAP 6.4 #
#                                                #
##################################################

# Use the centos base image
FROM rhel7

MAINTAINER mamurai

# Update the system
RUN yum -y update;yum clean all

##########################################################
# Install Java JDK, SSH and other useful cmdline utilities
##########################################################
RUN yum -y install unzip java-1.7.0-openjdk  java-1.7.0-openjdk-devel;yum clean all
ENV JAVA_HOME /usr/lib/jvm/jre

# enabling sudo group for jboss
RUN echo '%jboss ALL=(ALL) ALL' >> /etc/sudoers

# enable networking
RUN echo "NETWORKING=yes" > /etc/sysconfig/network

#enable ssh access
RUN echo "sshd: ALL" > /etc/hosts.allow

# Create OS user jboss
RUN /usr/sbin/useradd jboss && \
    echo "jboss" | /usr/bin/passwd --stdin jboss

############################################
# Install JBoss EAP 6.4.0GA
############################################
USER jboss
ENV HOME /home/jboss
ENV INSTALLDIR ${HOME}/App
ENV JBOSS_HOME ${INSTALLDIR}/jboss-eap-6.4
ENV CFG ${JBOSS_HOME}/standalone/configuration/standalone.xml
ENV EAP_ADMIN_USER admin
ENV EAP_ADMIN_PASSWORD redhat1!

RUN mkdir $INSTALLDIR && \
   mkdir $INSTALLDIR/software && \
   mkdir $INSTALLDIR/support && \
   mkdir $INSTALLDIR/jdbc
ADD software/jboss-eap-6.4.0.zip $INSTALLDIR/software/jboss-eap-6.4.0.zip 
ADD support/jboss_conf.cli $INSTALLDIR/support/jboss_conf.cli
ADD support/standalone.xml_pgsql $INSTALLDIR/support/standalone.xml_pgsql
ADD support/module.xml $INSTALLDIR/support/module.xml

USER root
RUN chown jboss:jboss $INSTALLDIR/software/*
RUN chown jboss:jboss $INSTALLDIR/support/*

USER jboss
RUN cd $INSTALLDIR && \
   unzip $INSTALLDIR/software/jboss-eap-6.4.0.zip
RUN $INSTALLDIR/jboss-eap-6.4/bin/add-user.sh -u $EAP_ADMIN_USER -p $EAP_ADMIN_PASSWORD -s


# Get PostgreSQL JDBC driver 
RUN curl -o $INSTALLDIR/jdbc/postgresql-9.3-1102.jdbc4.jar https://jdbc.postgresql.org/download/postgresql-9.3-1102.jdbc4.jar

# Modify JBoss Setting
RUN mkdir -p $JBOSS_HOME/modules/org/postgresql/Driver/main && \
    cp  $INSTALLDIR/jdbc/postgresql-9.3-1102.jdbc4.jar $JBOSS_HOME/modules/org/postgresql/Driver/main && \
    cp  $INSTALLDIR/support/module.xml $JBOSS_HOME/modules/org/postgresql/Driver/main

RUN mv $CFG ${CFG}.orig && \
   cp $INSTALLDIR/support/standalone.xml_pgsql $CFG
 

# Command line shortcuts
RUN echo "export JAVA_HOME=/usr/lib/jvm/jre" >> $HOME/.bash_profile
RUN echo "export JBOSS_HOME=$JBOSS_HOME" >> $HOME/.bash_profile
RUN echo "alias ll='ls -l --color=auto'" >> $HOME/.bash_profile
RUN echo "alias grep='grep --color=auto'" >> $HOME/.bash_profile
RUN echo "alias c='clear'" >> $HOME/.bash_profile
RUN echo "alias sjb='$JBOSS_HOME/bin/standalone.sh -c standalone.xml'" >> $HOME/.bash_profile
RUN echo "alias xjb='$JBOSS_HOME/bin/jboss-cli.sh --commands=connect,:shutdown'" >> $HOME/.bash_profile

RUN echo 'export DB_PORT_5432_TCP_ADDR=`cat /var/run/jboss/DB_PORT_5432_TCP_ADDR`' >> $JBOSS_HOME/bin/standalone.conf
RUN echo 'export DB_PORT_5432_TCP_PORT=`cat /var/run/jboss/DB_PORT_5432_TCP_PORT`' >> $JBOSS_HOME/bin/standalone.conf

# Start JBoss EAP and Run CLI Scripts 
#RUN nohup ${JBOSS_HOME}/bin/standalone.sh -c standalone.xml 2>&1 > /dev/null &
#RUN echo "Starting JBoss EAP ..."
#RUN sleep 30
#RUN ${JBOSS_HOME}/bin/jboss-cli.sh --connect --file=${INSTALLDIR}/support/jboss_conf.cli




# Create /home/jboss/run.sh startup script
USER root
RUN echo "#!/bin/bash" > $HOME/run.sh
RUN echo "echo JBoss EAP Start script" >> $HOME/run.sh

RUN echo "if [ ! -e ${CFG}_INIT ]; then" >> $HOME/run.sh
RUN echo "	cp -p ${CFG} ${CFG}_INIT" >> $HOME/run.sh
RUN echo "	chown jboss:jboss ${CFG}_INIT" >> $HOME/run.sh
RUN echo "	mkdir -p $HOME/env" >> $HOME/run.sh
RUN echo "	echo \$DB_PORT_5432_TCP_ADDR > $HOME/env/DB_PORT_5432_TCP_ADDR" >> $HOME/run.sh
RUN echo "	echo \$DB_PORT_5432_TCP_PORT > $HOME/env/DB_PORT_5432_TCP_PORT" >> $HOME/run.sh
RUN echo "	sed -i \"s/DB_PORT_5432_TCP_ADDR/\$DB_PORT_5432_TCP_ADDR/\"  ${CFG}" >> $HOME/run.sh
RUN echo "	sed -i \"s/DB_PORT_5432_TCP_PORT/\$DB_PORT_5432_TCP_PORT/\"  ${CFG}" >> $HOME/run.sh
RUN echo "else" >> $HOME/run.sh
RUN echo "	OLD_ADDR=\`cat $HOME/env/DB_PORT_5432_TCP_ADDR\`" >> $HOME/run.sh
RUN echo "	OLD_PORT=\`cat $HOME/env/DB_PORT_5432_TCP_PORT\`" >> $HOME/run.sh
RUN echo "	sed -i \"s/\${OLD_ADDR}:\${OLD_PORT}/\${DB_PORT_5432_TCP_ADDR}:\${DB_PORT_5432_TCP_PORT}/\"  ${CFG}" >> $HOME/run.sh
RUN echo "	echo \$DB_PORT_5432_TCP_ADDR > $HOME/env/DB_PORT_5432_TCP_ADDR" >> $HOME/run.sh
RUN echo "	echo \$DB_PORT_5432_TCP_PORT > $HOME/env/DB_PORT_5432_TCP_PORT" >> $HOME/run.sh
RUN echo "fi" >> $HOME/run.sh
RUN echo 'runuser -l jboss -c "$INSTALLDIR/jboss-eap-6.4/bin/standalone.sh -c standalone.xml -b 0.0.0.0 -bmanagement 0.0.0.0"' >> $HOME/run.sh
RUN echo "while [[ true ]];do" >>$HOME/run.sh
RUN echo "	/bin/bash" >> $HOME/run.sh
RUN echo "done" >> $HOME/run.sh
RUN chmod +x $HOME/run.sh


# Clean up
#RUN rm -rf $INSTALLDIR/support
#RUN rm -rf $INSTALLDIR/software

EXPOSE 8080 9990 9999

CMD /home/jboss/run.sh

# Finished
