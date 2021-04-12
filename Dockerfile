ARG HADOOP_VERSION=3.2.2
ARG BASE=pilillo/hadoop:${HADOOP_VERSION}

FROM ${BASE} as BASE
ARG HADOOP_VERSION

ARG METASTORE_VERSION=3.1.2
ARG HIVE_DOWNLOAD_URL=https://repo1.maven.org/maven2/org/apache/hive/hive-standalone-metastore/${METASTORE_VERSION}/hive-standalone-metastore-${METASTORE_VERSION}-bin.tar.gz
ARG INSTALLATION_DIR="/opt"
ARG METASTORE_PORT=9083

ARG HIVE_USER=hive
ARG HIVE_UID=186

ARG MARIADB_VERSION=2.7.2
ARG METASTORE_DIR_NAME=hive-metastore

ENV HIVE_METASTORE_HOME=${INSTALLATION_DIR}/${METASTORE_DIR_NAME}
ENV HIVE_METASTORE_CONF_DIR=${HIVE_METASTORE_HOME}/conf

WORKDIR ${INSTALLATION_DIR}

USER root

RUN useradd -u ${HIVE_UID} ${HIVE_USER} \
    && usermod -a -G ${HADOOP_GROUP} ${HIVE_USER}

# add hive standalone metastore
RUN curl ${HIVE_DOWNLOAD_URL} | tar xvz -C ${INSTALLATION_DIR} \
    && mv apache-hive-metastore-${METASTORE_VERSION}-bin ${METASTORE_DIR_NAME}

# https://kontext.tech/column/hadoop/415/hive-exception-in-thread-main-javalangnosuchmethoderror-comgooglecommon
# solve guava mismatch between hadoop/hive libs
# ls /opt/hadoop/share/hadoop/common/lib/guava*-jre.jar | grep -o -E '[0-9]+.[0.9]+'
RUN rm ${HIVE_METASTORE_HOME}/lib/guava*.jar \ 
    && cp ${HADOOP_HOME}/share/hadoop/common/lib/guava*-jre.jar ${HIVE_METASTORE_HOME}/lib/

# add maria db client
RUN curl https://dlm.mariadb.com/1496775/Connectors/java/connector-java-${MARIADB_VERSION}/mariadb-java-client-${MARIADB_VERSION}.jar \
    && ln -s ${INSTALLATION_DIR}/mariadb-java-client-${MARIADB_VERSION}.jar ${HADOOP_HOME}/share/hadoop/common/lib/ \
    && ln -s ${INSTALLATION_DIR}/mariadb-java-client-${MARIADB_VERSION}.jar ${HIVE_METASTORE_HOME}/lib/

RUN chown -R ${HIVE_USER}:${HADOOP_GROUP} ${HIVE_METASTORE_HOME}

WORKDIR ${HIVE_METASTORE_HOME}

USER ${HIVE_USER}

EXPOSE ${METASTORE_PORT}

ENTRYPOINT ["/opt/hive-metastore/bin/start-metastore"]
CMD ["-p", ${METASTORE_PORT}]