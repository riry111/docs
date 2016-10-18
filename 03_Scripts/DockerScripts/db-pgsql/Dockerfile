FROM centos:centos6

MAINTAINER M.Murai

########################
# Install PostgreSQL 9.3
########################
RUN yum -y install http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-redhat93-9.3-1.noarch.rpm
RUN yum -y install postgresql93-server postgresql93-contrib;yum clean all
RUN service postgresql-9.3 initdb

# PostgreSQL setup
USER postgres
ENV PGDATA /var/lib/pgsql/9.3/data
ENV PGINST /usr/pgsql-9.3

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible. 
RUN echo "host    all         all         0.0.0.0/0               md5" >> $PGDATA/pg_hba.conf
RUN echo "" >> $PGDATA/pg_hba.conf
RUN echo "listen_addresses='*'" >> $PGDATA/postgresql.conf
RUN echo "" >> $PGDATA/postgresql.conf

# Start PostgreSQL
# Create a PostgreSQL role named ``[jp|apac]customers`` with ``[jp|apac]customers`` as the password and
# then create a database `[jp|apac]customers` owned by the ``[jp|apac]customers`` role.
ADD data/SampleData_postgresql.sql SampleData_postgresql.sql
RUN $PGINST/bin/pg_ctl start -w -D $PGDATA && \ 
    $PGINST/bin/psql --command "ALTER USER postgres encrypted password 'postgres';" && \
    $PGINST/bin/psql --command "CREATE USER jpcustomers WITH SUPERUSER PASSWORD 'jpcustomers';" && \
    $PGINST/bin/psql --command "CREATE DATABASE jpcustomers WITH OWNER jpcustomers encoding 'UTF8';" && \
    $PGINST/bin/psql --command "CREATE USER apaccustomers WITH SUPERUSER PASSWORD 'apaccustomers';" && \
    $PGINST/bin/psql --command "CREATE DATABASE apaccustomers WITH OWNER apaccustomers encoding 'UTF8';" && \
    $PGINST/bin/psql -a -f SampleData_postgresql.sql

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]



# Create /usr/local/bin/run.sh startup script
USER root
RUN echo "#!/bin/bash" >> /usr/local/bin/run.sh
RUN echo "service postgresql-9.3 start " >> /usr/local/bin/run.sh
RUN echo "while [[ true ]];do" >> /usr/local/bin/run.sh
RUN echo "/bin/bash" >> /usr/local/bin/run.sh
RUN echo "done" >> /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh


EXPOSE 5432 

CMD /usr/local/bin/run.sh

