#!/bin/sh

set -e

# instantiate calicoctl in /opt/bin/cni, including a wrapper around
# the bin that points to the correct etcd endpoint and etcd
# certificate data
cp -v /calicoctl /host/opt/cni/bin/calicoctl.bin
[ -x /host/opt/cni/bin/calicoctl.bin ] || chmod +x /host/opt/cni/bin/calicoctl.bin

if [ ! -z "$ETCD_KEY" ]; then
    DIR=$(dirname /host/$ETCD_KEY_FILE)
    mkdir -p $DIR
    cat <<EOF>/host/$ETCD_KEY_FILE
$ETCD_KEY
EOF
    chmod 600 /host/$ETCD_KEY_FILE
fi;

if [ ! -z "$ETCD_CA_CERT" ]; then
    DIR=$(dirname /host/$ETCD_CA_CERT_FILE)
    mkdir -p $DIR
    cat <<EOF>/host/$ETCD_CA_CERT_FILE
$ETCD_CA_CERT
EOF
    chmod 600 /host/$ETCD_CA_CERT_FILE
fi;

if [ ! -z "$ETCD_CERT" ]; then
    DIR=$(dirname /host/$ETCD_CERT_FILE)
    mkdir -p $DIR
    cat <<EOF>/host/$ETCD_CERT_FILE
$ETCD_CERT
EOF
    chmod 600 /host/$ETCD_CERT_FILE
fi;

# This looks a bit funny.  Notice that if $ETCD_ENDPOINTS and friends
# are defined in this (calico node initContainer/startup) context;
# generate a shell script to set the values on the host where thse
# variables will *not* be set
cat <<EOF>/host/opt/cni/bin/calicoctl
#!/bin/bash
#
# do *NOT* modify this file; this is autogenerated by the calico-node
# deployment startup process

export ETCD_ENDPOINTS="${ETCD_ENDPOINTS}"

[ -e "${ETCD_KEY_FILE}" ] && export ETCD_KEY_FILE="${ETCD_KEY_FILE}"
[ -e "${ETCD_CERT_FILE}" ] && export ETCD_CERT_FILE="${ETCD_CERT_FILE}"
[ -e "${ETCD_CA_CERT_FILE}" ] && export ETCD_CA_CERT_FILE="${ETCD_CA_CERT_FILE}"

exec /opt/cni/bin/calicoctl.bin \$*
EOF

chmod +x /host/opt/cni/bin/calicoctl
