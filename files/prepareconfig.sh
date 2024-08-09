#!/command/with-contenv /bin/bash

if [ ! -v HIDEME_USERNAME ]; then
    export HIDEME_USERNAME=""
fi
if [ ! -v HIDEME_PASSWORD ]; then
    export HIDEME_PASSWORD=""
fi
if [ ! -v HIDEME_TOKEN ]; then
    export HIDEME_TOKEN=""
fi
if [ ! -v HIDEME_SERVER ]; then
    export HIDEME_SERVER="any"
fi
if [ ! -v HIDEME_PORT_FORWARDING ]; then
    export HIDEME_PORT_FORWARDING="true"
fi
if [ ! -v HIDEME_FORCE_DNS ]; then
    export HIDEME_FORCE_DNS="true"
fi
if [ ! -v HIDEME_IPV4 ]; then
    export HIDEME_IPV4="true"
fi
if [ ! -v HIDEME_IPV6 ]; then
    export HIDEME_IPV6="true"
fi
if [ ! -v HIDEME_ALLOW_NETWORKS ]; then
    export HIDEME_ALLOW_NETWORKS=""
fi

mkdir -p /opt/hide.me/etc
cd /opt/hide.me/

if [[ ! -e /tmp/hide.me.conf ]]; then
    ARGS=""
    if [[ ${HIDEME_PORT_FORWARDING,,} = "true" ]]; then
        ARGS="-pf "
    fi
    if [[ ${HIDEME_FORCE_DNS,,} = "true" ]]; then
        ARGS="${ARGS}-forceDns "
    fi
    HIDEME_ALLOW_DOCKER_NETWORK="true"
    if [[ ${HIDEME_ALLOW_DOCKER_NETWORK,,} = "true" ]]; then
        networks4=""
        networks6=""
        networks=""

        if [[ ${HIDEME_IPV4,,} = "true" ]]; then
            networks4=$(for if in $(ip -o link | awk -F'[ @:]' '{print $3}'); do
                if [ ${if} = lo ]; then continue; fi
                ip -o -4 address show ${if} | awk '{print $4}' | xargs | sed 's/ /,/g'
            done)
        fi
        if [[ ${HIDEME_IPV6,,} = "true" ]]; then
            networks6=$(for if in $(ip -o link | awk -F'[ @:]' '{print $3}'); do
                if [ ${if} = lo ]; then continue; fi
                ip -o -6 address show ${if} | awk '{print $4}' | xargs | sed 's/ /,/g'
            done)
        fi
        if [[ ! -z "${networks4}" && ! -z "${networks6}" ]]; then
            networks="${networks4},${networks6}"
        else
            networks="${networks4}${networks6}"
        fi
        if [[ ! -z "${networks}" && ! -z "${HIDEME_ALLOW_NETWORKS}" ]]; then
            HIDEME_ALLOW_NETWORKS="${HIDEME_ALLOW_NETWORKS},${networks}"
        else
            HIDEME_ALLOW_NETWORKS="${HIDEME_ALLOW_NETWORKS}${networks}"
        fi
    fi
    echo "Config file missing, create it.."
    /opt/hide.me/hide.me ${ARGS} -s ${HIDEME_ALLOW_NETWORKS} conf >/tmp/hide.me.conf
    if [[ ${HIDEME_IPV4,,} = "false" ]]; then
        sed -i 's/IPv4: true/IPv4: false/g' /tmp/hide.me.conf
    fi
    if [[ ${HIDEME_IPV6,,} = "false" ]]; then
        sed -i 's/IPv6: true/IPv6: false/g' /tmp/hide.me.conf
    fi
    echo "Done."
fi

if [[ -e /opt/hide.me/etc/accessToken.txt ]]; then
    HIDEME_TOKEN=$(cat /opt/hide.me/etc/accessToken.txt | tr -d '\t\n\r ')
fi

if [[ -z ${HIDEME_USERNAME} && -z ${HIDEME_PASSWORD} && -z ${HIDEME_TOKEN} ]]; then
    echo -e "\nNo username, password or access token supplied, cannot continue!\n\n"
    sleep 1
    exit 1
fi

if [[ -z ${HIDEME_SERVER} ]]; then
    HIDEME_SERVER="any"
fi

if [[ ${HIDEME_TOKEN} && ! -e /opt/hide.me/etc/accessToken.txt ]]; then
    echo "${HIDEME_TOKEN}" >/opt/hide.me/etc/accessToken.txt
    chmod go-rwx /opt/hide.me/etc/accessToken.txt
fi

if [[ -z ${HIDEME_TOKEN} && ! -e /opt/hide.me/etc/accessToken.txt ]]; then
    echo "No token supplied, fetching online.."
    data="{"
    data=${data}'"domain":"hide.me",'
    data=${data}'"host":"",'
    data=${data}'"username":"'${HIDEME_USERNAME}'",'
    data=${data}'"password":"'${HIDEME_PASSWORD}'"'
    data=${data}"}"
    url="https://${HIDEME_SERVER}.hideservers.net:432/v1.0.0/accessToken"
    HIDEME_TOKEN=$(curl -s -f --cacert /opt/hide.me/CA.pem -X POST --data-binary ${data} ${url})
    if [[ $? == "22" ]]; then
        echo -e "\nFailed at fetching token, cannot continue!\nMaybe try again later.\n\n"
        exit 1
    fi
    HIDEME_TOKEN=${HIDEME_TOKEN//"\""/}
    echo "${HIDEME_TOKEN}" >/opt/hide.me/etc/accessToken.txt
    chmod go-rwx /opt/hide.me/etc/accessToken.txt
    echo -e "\n\nToken: ${HIDEME_TOKEN}\n\n"
fi
