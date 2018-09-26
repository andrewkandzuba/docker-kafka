#!/bin/sh

# Optional ENV variables:
# * ADVERTISED_HOST: the external ip for the container, e.g. `docker-machine ip \`docker-machine active\``
# * ADVERTISED_PORT: the external port for Kafka, e.g. 9092
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
# * LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
# * LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
# * NUM_PARTITIONS: configure the default number of log partitions per topic

# Configure advertised host/port if we run in helios
if [ ! -z "$HELIOS_PORT_kafka" ]; then
    ADVERTISED_HOST=`echo $HELIOS_PORT_kafka | cut -d':' -f 1 | xargs -n 1 dig +short | tail -n 1`
    ADVERTISED_PORT=`echo $HELIOS_PORT_kafka | cut -d':' -f 2`
fi

# Force new line to the end of config file
echo "" >> $KAFKA_HOME/config/server.properties

# Set the external host and port
if [ ! -z "$ADVERTISED_HOST" ]; then
    echo "advertised host: $ADVERTISED_HOST"
    if grep -q "^advertised.host.name" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(advertised.host.name)=(.*)/\1=$ADVERTISED_HOST/g" $KAFKA_HOME/config/server.properties
    else
        echo "advertised.host.name=$ADVERTISED_HOST" >> $KAFKA_HOME/config/server.properties
    fi
fi
if [ ! -z "$ADVERTISED_PORT" ]; then
    echo "advertised port: $ADVERTISED_PORT"
    if grep -q "^advertised.port" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(advertised.port)=(.*)/\1=$ADVERTISED_PORT/g" $KAFKA_HOME/config/server.properties
    else
        echo "advertised.port=$ADVERTISED_PORT" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Set transaction.state.log.replication.factor
if [ ! -z "$TX_REPLICATION_FACTOR" ]; then
    echo "transaction.state.log.replication.factor: $TX_REPLICATION_FACTOR"
    if grep -q "^transaction.state.log.replication.factor" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(transaction.state.log.replication.factor)=(.*)/\1=$TX_REPLICATION_FACTOR/g" $KAFKA_HOME/config/server.properties
    else
        echo "transaction.state.log.replication.factor=$TX_REPLICATION_FACTOR" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Set transaction.state.log.min.isr
if [ ! -z "$TX_MIN_ISR" ]; then
    echo "transaction.state.log.min.isr: $TX_MIN_ISR"
    if grep -q "^transaction.state.log.min.isr" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(transaction.state.log.min.isr)=(.*)/\1=$TX_MIN_ISR/g" $KAFKA_HOME/config/server.properties
    else
        echo "transaction.state.log.min.isr=$TX_MIN_ISR" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Set transaction.state.log.min.isr
if [ ! -z "$TX_MIN_PARTITIONS" ]; then
    echo "transaction.state.log.num.partitions: $TX_MIN_PARTITIONS"
    if grep -q "^transaction.state.log.num.partitions" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(transaction.state.log.num.partitions)=(.*)/\1=$TX_MIN_PARTITIONS/g" $KAFKA_HOME/config/server.properties
    else
        echo "transaction.state.log.num.partitions=$TX_MIN_PARTITIONS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Set transaction.state.log.min.isr
if [ ! -z "$TX_TIMEOUT" ]; then
    echo "transaction.timeout.ms: $TX_TIMEOUT"
    if grep -q "^transaction.timeout.ms" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(transaction.timeout.ms)=(.*)/\1=$TX_TIMEOUT/g" $KAFKA_HOME/config/server.properties
    else
        echo "transaction.timeout.ms=$TX_TIMEOUT" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Set transaction.state.log.min.isr
if [ ! -z "$ZOOKEEPER_CONNECT" ]; then
    echo "zookeeper.connect: $ZOOKEEPER_CONNECT"
    if grep -q "^zookeeper.connect" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(zookeeper.connect)=(.*)/\1=$ZOOKEEPER_CONNECT/g" $KAFKA_HOME/config/server.properties
    else
        echo "zookeeper.connect=$ZOOKEEPER_CONNECT" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Set the zookeeper chroot
if [ ! -z "$ZK_CHROOT" ]; then
    # wait for zookeeper to start up
    until /usr/share/zookeeper/bin/zkServer.sh status; do
      sleep 0.1
    done

    # create the chroot node
    echo "create /$ZK_CHROOT \"\"" | /usr/share/zookeeper/bin/zkCli.sh || {
        echo "can't create chroot in zookeeper, exit"
        exit 1
    }

    # configure kafka
    sed -r -i "s/(zookeeper.connect)=(.*)/\1=localhost:2181\/$ZK_CHROOT/g" $KAFKA_HOME/config/server.properties
fi

# Allow specification of log retention policies
if [ ! -z "$LOG_RETENTION_HOURS" ]; then
    echo "log retention hours: $LOG_RETENTION_HOURS"
    sed -r -i "s/(log.retention.hours)=(.*)/\1=$LOG_RETENTION_HOURS/g" $KAFKA_HOME/config/server.properties
fi
if [ ! -z "$LOG_RETENTION_BYTES" ]; then
    echo "log retention bytes: $LOG_RETENTION_BYTES"
    sed -r -i "s/#(log.retention.bytes)=(.*)/\1=$LOG_RETENTION_BYTES/g" $KAFKA_HOME/config/server.properties
fi

# Configure the default number of log partitions per topic
if [ ! -z "$NUM_PARTITIONS" ]; then
    echo "default number of partition: $NUM_PARTITIONS"
    sed -r -i "s/(num.partitions)=(.*)/\1=$NUM_PARTITIONS/g" $KAFKA_HOME/config/server.properties
fi

# Enable/disable auto creation of topics
if [ ! -z "$AUTO_CREATE_TOPICS" ]; then
    echo "auto.create.topics.enable: $AUTO_CREATE_TOPICS"
    echo "auto.create.topics.enable=$AUTO_CREATE_TOPICS" >> $KAFKA_HOME/config/server.properties
fi

# Provide path to keystore
if [ ! -z "$SSL_KEYSTORE_LOCATION" ]; then
    echo "ssl.keystore.location: $SSL_KEYSTORE_LOCATION"
    if grep -q "^ssl.keystore.location" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(ssl.keystore.location)=(.*)/\1=$SSL_KEYSTORE_LOCATION/g" $KAFKA_HOME/config/server.properties
    else
        echo "ssl.keystore.location=$SSL_KEYSTORE_LOCATION" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Provide keystore's password
if [ ! -z "$SSL_KEYSTORE_PASSWORD" ]; then
    echo "ssl.keystore.password: $SSL_KEYSTORE_PASSWORD"
    if grep -q "^ssl.keystore.password" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(ssl.keystore.password)=(.*)/\1=$SSL_KEYSTORE_PASSWORD/g" $KAFKA_HOME/config/server.properties
    else
        echo "ssl.keystore.password=$SSL_KEYSTORE_PASSWORD" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Provide path to trust store
if [ ! -z "$SSL_TRUSTSTORE_LOCATION" ]; then
    echo "ssl.truststore.location: $SSL_TRUSTSTORE_LOCATION"
    if grep -q "^ssl.truststore.location" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(ssl.truststore.location)=(.*)/\1=$SSL_TRUSTSTORE_LOCATION/g" $KAFKA_HOME/config/server.properties
    else
        echo "ssl.truststore.location=$SSL_TRUSTSTORE_LOCATION" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Provide trust's store password
if [ ! -z "$SSL_TRUSTSTORE_PASSWORD" ]; then
    echo "ssl.truststore.password: $SSL_TRUSTSTORE_PASSWORD"
    if grep -q "^ssl.truststore.password" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(ssl.truststore.password)=(.*)/\1=$SSL_TRUSTSTORE_PASSWORD/g" $KAFKA_HOME/config/server.properties
    else
        echo "ssl.truststore.password=$SSL_TRUSTSTORE_PASSWORD" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Provide trust's store password
if [ ! -z "$SECURITY_INTER_BROKER_PROTOCOL" ]; then
    echo "security.inter.broker.protocol: $SECURITY_INTER_BROKER_PROTOCOL"
    if grep -q "^security.inter.broker.protocol" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(security.inter.broker.protocol)=(.*)/\1=$SECURITY_INTER_BROKER_PROTOCOL/g" $KAFKA_HOME/config/server.properties
    else
        echo "security.inter.broker.protocol=$SECURITY_INTER_BROKER_PROTOCOL" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Provide trust's store password
if [ ! -z "$INTER_BROKER_LISTENER_NAME" ]; then
    echo "inter.broker.listener.name: $INTER_BROKER_LISTENER_NAME"
    if grep -q "^inter.broker.listener.name" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(inter.broker.listener.name)=(.*)/\1=$INTER_BROKER_LISTENER_NAME/g" $KAFKA_HOME/config/server.properties
    else
        echo "inter.broker.listener.name=$INTER_BROKER_LISTENER_NAME" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Provide advertised.listeners
if [ ! -z "$ADVERTISED_LISTENERS" ]; then
    echo "advertised.listeners: $ADVERTISED_LISTENERS"
    if grep -q "^advertised.listeners" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(advertised.listeners)=(.*)/\1=$ADVERTISED_LISTENERS/g" $KAFKA_HOME/config/server.properties
    else
        echo "advertised.listeners=$ADVERTISED_LISTENERS" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Provide ssl.client.auth
if [ ! -z "$SSL_CLIENT_AUTH" ]; then
    echo "ssl.client.auth: $SSL_CLIENT_AUTH"
    if grep -q "^ssl.client.auth" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(ssl.client.auth)=(.*)/\1=$SSL_CLIENT_AUTH/g" $KAFKA_HOME/config/server.properties
    else
        echo "ssl.client.auth=$SSL_CLIENT_AUTH" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Run Zookeeper
$KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties