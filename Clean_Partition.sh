#!/bin/sh -e

# informations
host="127.0.0.1"
port=9000
user=test
password="test"
database="default"
table="test"
parts=10
run=true

usage()
{
    echo "
USAGE:
   $0 [arguments...]
ARGUMENTS:
   --host          server host (default: \"$host\")
   --port          server port (default: \"$port\")
   --user,     -u  user name (default: \"$user\")
   --password, -p  password (default: \"$password\")
   --database, -d  database (default: \"$database\")
   --table,    -t  table (default: \"$table\")
   --parts,    -p  the number of last partitions that will not be deleted (default: \"$parts\")
   --dry-run,  -n  do not apply cleaning, only show partitions to clean out
    ";
}

while [ "$1" != "" ]; do
    case "$1" in
             --host )      host="$2";     shift;;
             --port )      port="$2";     shift;;
        -u | --user )      user="$2";     shift;;
        -p | --password )  password="$2"; shift;;
        -d | --database )  database="$2"; shift;;
        -t | --table )     table="$2";    shift;;
             --parts )     parts="$2";    shift;;
        -n | --dry-run )   run=false           ;;
        -h | --help )      usage;         exit;;
    esac
    shift
done

query="
SELECT
    DISTINCT partition
FROM system.parts
WHERE
database = '${database}'
AND table    = '${table}'
AND active
ORDER BY partition DESC
LIMIT ${parts}, 100000000000000
FORMAT TSVRaw
"

echo "Connecting to ${host}:${port}";
echo "Cleaning parts for '${database}.${table}' table"
$run || echo 'Running'

echo "$query" | clickhouse-client --host "$host" --port "$port" --user "$user" --password "$password" | while read -r partition; do
    echo "ALTER TABLE \"$database\".\"$table\" DROP PARTITION ${partition}"
    if $run; then
      clickhouse-client --host "$host" --port "$port" --user "$user" --password "$password" -q "ALTER TABLE \"$database\".\"$table\" DROP PARTITION ${partition}"
    else
      true
    fi
done
