##################################################
#                                                #
# Creates a base rhel6  image with OpenSSH       #
#                                                #
##################################################

# Use the centos base image
FROM registry.access.redhat.com/rhel6.5

MAINTAINER mamurai

# Setup init script
ADD init.sh /usr/local/bin/init.sh
RUN chmod u+x /usr/local/bin/init.sh

RUN mkdir /root/.ssh
RUN chmod 700 /root/.ssh
ADD authorized_keys /root/.ssh/authorized_keys
RUN chmod 600  /root/.ssh/authorized_keys


# Update the system
RUN yum -y update
RUN yum -y install openssh-server openssh openssh-clients unzip coreutils shadow-utils sudo
RUN yum clean all

#sshd setting
RUN cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
RUN sed -ri 's/^UsePAM yes/#UsePAM yes/' /etc/ssh/sshd_config
RUN sed -ri 's/#^UsePAM no/UsePAM no/' /etc/ssh/sshd_config

# Set root password
RUN echo 'root:redhat1!' |chpasswd


EXPOSE 22 8080 9990 9999

CMD ["/usr/local/bin/init.sh"]

