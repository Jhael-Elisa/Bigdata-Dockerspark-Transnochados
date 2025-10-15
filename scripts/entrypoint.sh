#!/bin/bash

# Initialize Hive metastore if needed
if [ "$1" = "hive" ] && [ "$2" = "--service" ] && [ "$3" = "metastore" ]; then
    if [ ! -f /opt/hive/metastore_db/db.lck ]; then
        $HIVE_HOME/bin/schematool -dbType derby -initSchema
    fi
fi

# Execute the command passed to docker run
exec "$@"