#! /usr/bin/env bash

for str in $(cat interfaces)
do
    IFS=":"
    set -- $str
    iface=$1
    traf_dir=$2
#   echo "iface>>>$iface<<<"
#   echo "traf_dir>>>$traf_dir<<<"
    res=$(ip link show $iface | grep -i 'state UP')
    if [[ $res ]]
    then
	echo "ip link $iface status: UP-$res"
	echo "Traffic directory:$traf_dir"
	echo "Create config files and startup script"
        fsrvname="tshark-$iface.service"
        fstrname="tshark-$iface-start.sh"
        echo $fsrvname
        echo $fstrname
        touch $fsrvname
        chmod +rw $fsrvname
        touch $fstrname
        chmod +rwx $fstrname
#
        chown root $fsrvname
        chgrp root $fsrvname
# service file
        echo "[Unit]">>$fsrvname
        echo "Description=Tshark-$iface-service">>$fsrvname
        echo "After=network.target">>$fsrvname
        echo "Requires=network.service">>$fsrvname
        echo "[Service]">>$fsrvname
        echo "Type=forking">>$fsrvname
        echo "User=denis">>$fsrvname
        echo "Group=denis">>$fsrvname
        echo "OOMScoreAdjust=-100">>$fsrvname
        echo "ExecStart=\"/usr/local/etc/$fstrname\"">>$fsrvname
        echo "RestartSec=10us">>$fsrvname
        echo "Restart=always">>$fsrvname
        echo "[Install]">>$fsrvname
        echo "WantedBy=multi-user.target">>$fsrvname
# startup script
        echo "#! /usr/bin/env sh">>$fstrname
        echo "/usr/sbin/tshark -i $iface -b filesize:200000 -b files:5000 -w $traf_dir/cap.pcap &">>$fstrname
        echo "echo \"tshark-$iface service PID is \$!\"">>$fstrname
        echo "sleep 1">>$fstrname

    res=`rm -r $traf_dir/*`
    echo "Result clear storage: $res"
    res=`cp $fstrname /usr/local/etc/`
    echo "Result copy startup script:$res"
    echo "Copy file $fsrvname in service directory"
    res=`cp $fsrvname /etc/systemd/system/`
    echo "Result copy service configuration:$res"
    res=`systemctl daemon-reload`
    echo "Result reload systemd:$res"
    res=`systemctl enable $fsrvname`
    echo "Result enabling systemd:$res"

    res=`systemctl start $fsrvname`
    echo "Result start service:$res"

    else
	echo "link is down or not present interface:$iface"
	echo "Configuration not create !!!"
    fi
    echo "-----"
done
