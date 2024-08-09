#!/usr/bin/env bash
#usage:   ./dnsleaktest.sh [-i interface_ip|interface_name]
#example: ./dnsleaktest.sh -i eth1
#         ./dnsleaktest.sh -i 10.0.0.2

if ! pidof hide.me; then
    echo -e "\nhide.me not running, healthcheck failed!\n\n"
    exit 1
fi

api_domain='bash.ws'

getopts "i:" opt
interface=$OPTARG

if [ -z "$interface" ]; then
    curl_interface=""
    ping_interface=""
else
    curl_interface="--interface ${interface}"
    ping_interface="-I ${interface}"
    echo "Interface: ${interface}"
    echo ""
fi

function check_internet_connection {
    curl --silent --head ${curl_interface} --request GET "https://${api_domain}" | grep "200 OK" >/dev/null
    if [ $? -ne 0 ]; then
        echo "No internet connection."
        exit 1
    fi
}

check_internet_connection

if hash shuf 2>/dev/null; then
    id=$(shuf -i 1000000-9999999 -n 1)
else
    id=$(jot -w %i -r 1 1000000 9999999)
fi

for i in $(seq 1 10); do
    ping -c 1 ${ping_interface} "${i}.${id}.${api_domain}" >/dev/null 2>&1
done

function print_servers {
    echo ${result_json} |
        jq --monochrome-output \
            --raw-output \
            ".[] | select(.type == \"${1}\") | \"\(.ip)\(if .country_name != \"\" and  .country_name != false then \" [\(.country_name)\(if .asn != \"\" and .asn != false then \" \(.asn)\" else \"\" end)]\" else \"\" end)\""
}

result_json=$(curl ${curl_interface} --silent "https://${api_domain}/dnsleak/test/${id}?json")
dns_count=$(print_servers "dns" | wc -l)

echo "Your IP:"
print_servers "ip"

echo ""
if [ ${dns_count} -eq "0" ]; then
    echo "No DNS servers found"
    exit 1
else
    if [ ${dns_count} -eq "1" ]; then
        echo "You use ${dns_count} DNS server:"
    else
        echo "You use ${dns_count} DNS servers:"
    fi
    print_servers "dns"
fi

echo ""
echo "Conclusion:"
print_servers "conclusion"
if [ "$(print_servers 'conclusion')" = "DNS is not leaking." ]; then
    exit 0
fi
exit 1
