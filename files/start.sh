#!/command/with-contenv /bin/bash
if [[ ! -v HIDEME_SERVER || -z "${HIDEME_SERVER}" ]]; then
    export HIDEME_SERVER="any"
fi
export HIDEME_SERVER=$(echo -n "${HIDEME_SERVER}" | cut -d "." -f 1)

/opt/hide.me/hide.me -c /tmp/hide.me.conf -t /opt/hide.me/etc/accessToken.txt connect $HIDEME_SERVER
