#!

function prov_list()
{
local i=0
cat /etc/kusanagi.d/profile.conf | awk -F / '/home\/'$1'\// {print $4}' | cut -d '"' -f1 | \
while read prov; do
   echo $((++i))". "$prov
done
}
