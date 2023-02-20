echo "$(date +"%Y-%m-%d %H:%M:%S Update Begin")"
docker pull busybox
docker run --network=bridge --rm -it busybox ifconfig
echo "$1"
echo "$(date +"%Y-%m-%d %H:%M:%S Update End")"