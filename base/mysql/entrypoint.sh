#!/usr/bin/env bash
set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

. /startup-scripts/functions.sh

ipaddr=$(hostname -i | awk ' { print $1 } ')
hostname=$(hostname)
echo "I AM $hostname - $ipaddr"

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
    CMDARG="$@"
fi

function testconn() {
    timeout 1 bash -c "cat < /dev/null > /dev/tcp/$1/3306"
}

service_name=$(hostname -f | grep -o '[^.]\+' | head -n2 | tail -n1)
if ! testconn "$service_name"; then
    echo "I am the Primary Node"
    init_mysql
    write_password_file
    exec mysqld --user=mysql --wsrep_cluster_name=$service_name --wsrep_node_name=$hostname \
    --wsrep_cluster_address=gcomm:// --wsrep_sst_method=xtrabackup-v2 \
    --wsrep_sst_auth="xtrabackup:$XTRABACKUP_PASSWORD" \
    --wsrep_node_address="$ipaddr" --pxc_strict_mode="$PXC_STRICT_MODE" $CMDARG
else
    echo "I am not the Primary Node"
    chown -R mysql:mysql /var/lib/mysql || true # default is root:root 777
    cluster_join=$(resolveip -s "${service_name}")
    touch /var/log/mysqld.log
    chown mysql:mysql /var/log/mysqld.log
    write_password_file
    exec mysqld --user=mysql --wsrep_cluster_name=$service_name --wsrep_node_name=$hostname \
    --wsrep_cluster_address="gcomm://$cluster_join" --wsrep_sst_method=xtrabackup-v2 \
    --wsrep_sst_auth="xtrabackup:$XTRABACKUP_PASSWORD" \
    --wsrep_node_address="$ipaddr" --pxc_strict_mode="$PXC_STRICT_MODE" $CMDARG
fi
