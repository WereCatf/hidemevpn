![Hide.me logo](/assets/logo.png)

# Hidemevpn

Hidemevpn is a simple Docker container for running the [hide.me VPN](https://hide.me/en/) client in a containerized environment quickly and easily. It allows you to route other containers' traffic through the VPN while preventing leaks. A kill switch is included!

## Usage

### Access token

To be able to connect to Hide.me servers, you need an access token. You can either supply your username and password via environment variables _HIDEME_USERNAME_ and _HIDEME_PASSWORD_ and the container will automatically attempt to fetch the token or you can supply the token directly via _HIDEME_TOKEN_ or via _accessToken.txt_ in the container's volume. If you are using username and password, the token will be printed out in the container's logs, so you can grab it from there and remove the username and password environment variables.

### Configuration

Create a _.env_ file with the following contents (these are the defaults) and then customize its contents to your liking:

```console
HIDEME_USERNAME=
HIDEME_PASSWORD=
HIDEME_TOKEN=
HIDEME_SERVER=any
HIDEME_PORT_FORWARDING=true
HIDEME_FORCE_DNS=true
HIDEME_IPV4=true
HIDEME_IPV6=false
HIDEME_ALLOW_NETWORKS=
HIDEME_INTERVAL=
```

_HIDEME_ALLOW_NETWORKS_ is a comma-separated list of [CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing#CIDR_notation) networks you wish to allow traffic from into the containerized, private network -- the hide.me client blocks all split network traffic by default for security reasons. If you are running another container within the hidemevpn network, like e.g. nginx, and you wish to allow your local devices to access the service, you need to export the corresponding port and then add your local network to _HIDEME_ALLOW_NETWORKS_, like e.g. if your LAN is _192.168.1.0/24_, you'd add that. Otherwise, you won't be able to access the service.

_HIDEME_INTERVAL_ allows you to specify an interval for automatically disconnecting from the VPN endpoint and reconnecting, which is most useful when using "any" as the endpoint as you'll likely end up with a new IP-address. You can specify the interval as either a constant one or give a range between two values to randomize the interval after every cycle. As an example, `HIDEME_INTERVAL="5m"` would produce a constant interval of 5 minutes and `HIDEME_INTERVAL="3h-2d"` would produce anything between 3 hours and 2 days.

_HIDEME_SERVER_ denotes the VPN endpoint to connect to, ie. basically what country. `any` would just choose randomly one, `dk` would choose a danish one and so on. Prepend the endpoint with `free-`, if you are using a free/trial account, like e.g. `free-fi`

### Launch container

Edit the _.env_ file to your liking, then launch a container with the following, while optionally setting up a volume (the `-v` argument) for it:

```console
docker run -v ./etc:/opt/hide.me/etc --env-file ./env --cap-add NET_ADMIN --sysctl net.ipv4.conf.all.src_valid_mark=1 --name hidemevpn -itd werecatf/hidemevpn:latest
```

### Launch using Docker compose

You can also use docker compose instead by creating and customizing a _docker-compose.yaml_ and firing it up with `docker compose up -d`:

```console
version: "3"
services:
  hidemevpn:
    container_name: hidemevpn
    image: werecatf/hidemevpn:latest
    env_file: .env
    cap_add:
      - NET_ADMIN
    sysctls:
      net.ipv4.conf.all.src_valid_mark: 1
    volumes:
      - ./etc:/opt/hide.me/etc
    restart: unless-stopped
    stdin_open: true
    tty: true
```

If you wish to route another container's traffic through the VPN, add something similar to the following at the bottom of the _docker-compose.yaml_ file:

```console
    ports:
      - 8080:8080 # Any port exposed by the "someservice" container has to be exported here.

  someservice:
    image: someone/someimage:latest
    container_name: someservice
    network_mode: "service:hidemevpn" # ** This is the important part to route the traffic through the VPN! **
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./someservice:/config
    restart: unless-stopped
    depends_on: # Optional: these lines ensure that these additional containers will not be started until the VPN is up.
      hidemevpn:
        condition: service_started
```

## Disclaimer

The creator(s) of this image are not affiliated with Hide.me and do not accept any responsibility with regards to you, the company, the services of theirs or anything else, whatsoever. You use this image at your own risk and responsibility.

healthcheck.sh adopted from dnsleaktest.sh by Macvk at <https://github.com/macvk/dnsleaktest> Thank you, Macvk!
Thank you to Hide.me as well for providing a good VPN service!
