FROM	rhel7.2
MAINTAINER mamurai <mamurai@redhat.com>

# Install packages necessary to run EAP
RUN     yum --disablerepo=* \
--enablerepo="rhel-7-server-rpms" \
--enablerepo="rhel-7-server-extras-rpms" \
--enablerepo="rhel-7-server-optional-rpms" \
update -y && \
        yum --disablerepo=* \
--enablerepo="rhel-7-server-rpms" \
--enablerepo="rhel-7-server-extras-rpms" \
--enablerepo="rhel-7-server-optional-rpms" \
install -y --setopt=tsflags=nodocs \
augeas \
bsdtar \
java-1.8.0-openjdk-devel \
less \
nmap-ncat \
procps-ng \
saxon \
tar \
unzip \
xmlstarlet && \
	yum clean all

# Create a user and group used to launch processes
# The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,
# so there is a high chance that this ID will be equal to the current user
# making it easier to use volumes (no permission issues)
RUN 	groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss

# Set the working directory to jboss' user home directory
WORKDIR /opt/jboss

# Specify the user which should be used to execute all commands below
USER 	jboss

# Set the JAVA_HOME variable to make it clear where Java is located
ENV JAVA_HOME /usr/lib/jvm/java

# Set the WILDFLY_VERSION env variable
ENV 	WILDFLY_VERSION 9.0.1.Final
ENV 	WILDFLY_SHA1 abe037d5d1cb97b4d07fbfe59b6a1345a39a9ae5
ENV 	JBOSS_HOME /opt/jboss/wildfly

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN 	cd $HOME \
    && curl -s -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && rm wildfly-$WILDFLY_VERSION.tar.gz

# Create a console administrator account
RUN	/opt/jboss/wildfly/bin/add-user.sh admin jboss#1! --silent

# Expose the ports we're interested in
EXPOSE 	8080 9990

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface
CMD 	["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]

