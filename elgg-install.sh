#!/bin/sh

set -e

WAIT_MYSQL_START="30" # In seconds
MYSQL_PORT="$MYSQL_PORT"
MYSQL_USER="$MYSQL_USER"
MYSQL_PASS="$MYSQL_PASS"
ELGG_DB_HOST="$ELGG_DB_HOST"
ELGG_DATA_ROOT="$ELGG_DATA_ROOT"

#wait for mysql
i=0
while ! netcat $ELGG_DB_HOST $MYSQL_PORT >/dev/null 2>&1 < /dev/null; do
  i=`expr $i + 1`
  if [ $i -ge $MYSQL_LOOPS ]; then
    echo "$(date) - ${ELGG_DB_HOST}:${MYSQL_PORT} still not reachable, giving up."
    exit 1
  fi
  echo "$(date) - waiting for ${ELGG_DB_HOST}:${MYSQL_PORT}... $i/$WAIT_MYSQL_START."
  sleep 1
done
echo "The MySQL server is ready."

echo "Starting installation elgg."
#This directory will hold Elgg's ``settings.php`` file after installation.
if [ ! -d "${ELGG_PATH}elgg-config/" ]; then
	mkdir "${ELGG_PATH}elgg-config/"
	chown -R www-data:www-data "${ELGG_PATH}elgg-config/"
fi

mkdir $ELGG_DATA_ROOT
chown -R www-data:www-data $ELGG_DATA_ROOT
chmod 770 -R $ELGG_DATA_ROOT

php	/elgg-docker/elgg-install.php
