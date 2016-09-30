#!/bin/bash
for VAR in `env`
do
  if [[ $VAR =~ ^KAFKA_ && ! $VAR =~ ^KAFKA_HOME && ! $VAR =~ ^KAFKA_SERVER_PROPERTIES && ! $VAR =~ ^KAFKA_FULL_NAME && ! $VAR =~ ^KAFKA_VERSION ]]; then
    kafka_name=`echo "$VAR" | sed -r "s/KAFKA_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
    env_var=`echo "$VAR" | sed -r "s/(.*)=.*/\1/g"`
    if egrep -q "(^|^#)$kafka_name=" $KAFKA_SERVER_PROPERTIES; then
        sed -r -i "s@(^|^#)($kafka_name)=(.*)@\2=${!env_var}@g" $KAFKA_SERVER_PROPERTIES #note that no config values may contain an '@' char
    else
        echo "$kafka_name=${!env_var}" >> $KAFKA_SERVER_PROPERTIES
    fi
  fi
done

KAFKA_PID=0

# see https://medium.com/@gchudnov/trapping-signals-in-docker-containers-7a57fdda7d86#.bh35ir4u5
term_handler() {
  echo 'Stopping Kafka....'
  if [ $KAFKA_PID -ne 0 ]; then
    kill -s TERM "$KAFKA_PID"
    wait "$KAFKA_PID"
  fi
  echo 'Kafka stopped.'
  exit
}

# Capture kill requests to stop properly
trap "term_handler" SIGHUP SIGINT SIGTERM
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_SERVER_PROPERTIES &
KAFKA_PID=$!

wait
