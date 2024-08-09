#!/command/with-contenv /bin/bash
if [ ! -v HIDEME_SERVER ]
then
	export HIDEME_SERVER="any"
fi

/opt/hide.me/hide.me -c /tmp/hide.me.conf -t /opt/hide.me/etc/accessToken.txt connect $HIDEME_SERVER
