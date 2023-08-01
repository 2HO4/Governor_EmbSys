
echo performance > /sys/devices/system/cpu/cpufreq/policy2/scaling_governor
echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
export LD_LIBRARY_PATH=/data/local/Working_dir
echo $1 > /sys/devices/system/cpu/cpufreq/policy2/scaling_max_freq
echo $2 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq

./graph_resnet50_all_pipe_sync --threads=4 --threads2=2 --n=100 --total_cores=6 --partition_point=11 --partition_point2=15 --order=G-B-L
