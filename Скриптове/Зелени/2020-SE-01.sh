#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Wrong number of arguments"
    exit 1
fi

if [[ ! -f $1 ]]; then
    touch $1
fi

if [[ ! -d $2 ]]; then
    echo "The second argument should be a directory"
    exit 3
fi

output=$1
dir=$2

echo "hostname,phy,vlans,hosts,failover,VPN-3DES-AES,peers,VLAN Trunk Ports,license,SN,key" > "$output"

while read -r file; do

    hostname=$(basename "$file" .log)
    phy=$(grep "Maximum Physical Interfaces" "$file" | cut -d':' -f2 | xargs)
    vlans=$(grep "VLANs" "$file" | cut -d':' -f2 | xargs)
    hosts=$(grep "Inside Hosts" "$file" | cut -d':' -f2 | xargs)
    failover=$(grep "Failover" "$file" | cut -d':' -f2 | xargs)
    vpn=$(grep "VPN-3DES-AES" "$file" | cut -d':' -f2 | xargs)
    peers=$(grep "\*Total VPN Peers" "$file" | cut -d':' -f2 | xargs)
    trunks=$(grep "VLAN Trunk Ports" "$file" | cut -d':' -f2 | xargs)
    license=$(grep "This platform has" "$file" | sed -E 's/.*has an{0,1} (.*) license\./\1/' | xargs)
    sn=$(grep "Serial Number" "$file" | cut -d':' -f2 | xargs)
    key=$(grep "Running Activation Key" "$file" | cut -d':' -f2 | xargs)

    # Запис във файла
    echo "$hostname,$phy,$vlans,$hosts,$failover,$vpn,$peers,$trunks,$license,$sn,$key" >> "$output"
done < <(find "$2" -type f | grep -E '.*\.log')