#!

hhvm_list()
{
cat /etc/kusanagi.d/profile.conf | grep PROFILE | cut -d '"' -f2 |\
while read line; do
	[ `kusanagi pro_status $line | grep HHVM 2>&1 >/dev/null;echo $?` -eq 0 ] && echo $line
done
}
#hhvm_list
