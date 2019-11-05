####################################
#   Multi-stage build
#       1. build hive metastore-standalone
#       2. run hive metastore-standalone
####################################

# Stage 1 - build hive metastore-standalone

FROM maven:3-jdk-8-slim as metastore-builder

RUN apt-get update && apt-get install -y apt-utils git

RUN git clone https://github.com/timveil/hive.git /tmp/hive

RUN cd /tmp/hive \
    && git checkout -f release-3.1.2 \
    && mvn -pl standalone-metastore -am clean package -DskipTests

# Stage 2 - run hive metastore-standalone

FROM timveil/docker-hadoop-core:3.1.x

LABEL maintainer="tjveil@gmail.com"

ENV METASTORE_HOME=/opt/hive-metastore

RUN apt-get update && apt-get install -y apt-utils && mkdir /opt/hive-metastore

COPY --from=metastore-builder /tmp/hive/standalone-metastore/target/*-bin.tar.gz /tmp/

ADD run.sh /run.sh
RUN chmod a+x /run.sh

RUN tar -xvf /tmp/*-bin.tar.gz -C /opt/hive-metastore --strip-components=1

ARG POSTGRESQL_JDBC_VERSION=42.2.8

# Install PostgreSQL JDBC driver
RUN curl -fSL https://jdbc.postgresql.org/download/postgresql-$POSTGRESQL_JDBC_VERSION.jar -o /opt/hive-metastore/lib/postgresql-jdbc.jar

ADD conf/metastore-log4j2.properties /opt/hive-metastore/conf
ADD conf/metastore-site.xml /opt/hive-metastore/conf

CMD ["/run.sh"]