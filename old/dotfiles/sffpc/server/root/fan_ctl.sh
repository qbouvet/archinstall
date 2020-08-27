#!/bin/bash


###
###	Fan control script for sffpc
###


### TODO
###
###	fix dev_path
###
###	add -h usage()
###



########################################################################
## Parameters for User
##



refresh_interval=1.5s 	# in seconds
hysterisis=3			# in degree c, set to 1 for no hysterisis effect
verbose=1				# enable for debug, disable for perf

# Fan curves defined by an array of temperatures (celsius) and a array of 
# corresponding speeds (%). Requirements : 
#	- same length
# 	- speed[i] is the speed for temperature in [temp[i], temp[i+1][
#	- first speed = minimum speed, last speed = maximum speed
#
#cpu_fan_curve_temps=( 0  55 62 67);
#cpu_fan_curve_speeds=(35 60 80 100);
#gpu_fan_curve_temps=( 0  45 52 62 68 72);
#gpu_fan_curve_speeds=(25 35 72 85 92 100);
cpu_fan_curve_temps=( 0  43 57 62 67);
cpu_fan_curve_speeds=(35 50 60 80 100);
gpu_fan_curve_temps=( 0  45 52 60 68 72);
gpu_fan_curve_speeds=(25 35 90 100 100 100);

# Minimum rotation speed, per fan, in percent and hex form
#
fan_case_min_hex=76 # 76=30% 
fan_case_min_pc=30
fan_cpu_min_hex=76	# 76=30% 
fan_cpu_min_pc=30
fan_gpu_min_hex=64	# 64=25%
fan_gpu_min_pc=25


# Legacy configuration variables
cpu_idle_temp=45	# map cpu fan speed between these temps
cpu_max_temp=67
gpu_idle_temp=45	# map gpu fan speed between these temps
gpu_max_temp=65









########################################################################
## Parameters NOT FOR USER
##

## PWM Devices file paths setup
##

if [ -d '/sys/devices/platform/nct6775.656/hwmon/hwmon1/' ]
then
	devs_path='/sys/devices/platform/nct6775.656/hwmon/hwmon1/'
elif [ -d '/sys/devices/platform/nct6775.656/hwmon/hwmon2/' ]
then
	devs_path='/sys/devices/platform/nct6775.656/hwmon/hwmon2/'  
elif [ -d '/sys/devices/platform/nct6775.656/hwmon/hwmon3/' ]
then
	devs_path='/sys/devices/platform/nct6775.656/hwmon/hwmon3/'  
else 
	return
fi

echo $devs_path

fan_case='pwm1'
fan_cpu='pwm2'
fan_gpu='pwm3'




########################################################################
## Fan curve functions
##

##  Queries the fan curve represented by the two arrays passed as arguments
##      $1  Array of temperatures
##      $2  Array of fan speeds
##      $3  current temperature
##
function query_curve 
{
    ## Inputs and output
    local -n temps=$1; local -n speeds=$2; curr_t=$3;
    res=100;
    
    ## Check array length are compatible
    if [ ${#temps[@]} -ne ${#speeds[@]} ]; then
        echo "81";
        return;
    fi
    
    array_len=${#speeds[@]};
    res_found="false";
    index=0
    
    while [ $index -lt $(($array_len -1)) ] && [ "$curr_t" -ge ${temps[(($index+1))]} ] ; do
        index=$(($index + 1))
    done
    
    echo ${speeds[$index]}
}

#	linearily maps a percentage value to [min_out, 255]
#	wraps interval_to_hex
#		$1 		val
#		$4 		min_out
function percent_to_hex
{
	pc=$1; min_out=$2;
	res=255;
	if [ "$pc" -ge "100" ] || [ "$pc" -lt "0" ]; then
	 	# invalid input
		res=255;
	elif [ "$pc" -eq "0" ];	then
		res=$min_out;
	else	
		# interpolation
		res=$(expr \( 255 \* $pc / 100 \));
        if [ $res -lt $min_out ]; then
            res=$min_out;
        fi
	fi
	echo $res;
}

#	Legacy fan curve function
#	linearily maps val from [min, max] -> [min_out, 255]
#		$1 		min
#		$2 		max
#		$3 		val
#		$4 		min_out
function interval_to_hex
{
	if [ "$3" -ge "$2" ]; then
	 	# above upper input bound
		res=255;
	elif [ "$3" -le "$1" ];	then
		# below lower input bounds
		res=$4;
	else	
		# interpolation
		res=$(expr \( 255 \* \( $3 - $1 \) \) / \( $2 - $1 \));
        if [ $res -lt $4 ]; then
            res=$4;
        fi
	fi
	echo $res;
}




########################################################################
## Device files IO functions
##

# 	Writes 0 to $1_enable to enable manual pwm control
function enable_pwm
{
	sudo bash -c "echo 0 > $devs_path$1_enable"
}

# 	Writes $2 to $1 to set the pwm speed of the device
#		$1		device file in which to write
#		$2		desired fan speed in [0-255] 
function write_to
{
	sudo bash -c "echo $2 > $devs_path$1"
}




########################################################################
## Temp monitoring functions
##

# 	Read CPU temp (on-die sensor)
function get_cpu_temp
{
	# alternative : cput=$(cat /sys/class/hwmon/hwmon0/device/hwmon/hwmon0/temp1_input)
	cput=$(cat /sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon0/temp1_input)
	# 32c is read as 32000 -> remove trailing zeroes
	expr \( 500 + $cput \) / 1000
}

#	Read gpu temp 
function get_gpu_temp
{
	# nvidia-smi = best solution
	nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader
	
	# Fall back if nvidia-smi is not available
	#temp_str=$(nvidia-settings -q GPUCoreTemp --terse)
	#temp=${temp_str:0:2}
	#echo $temp
}




########################################################################
## Execution
##

echo 

# initialize
enable_pwm $fan_case
enable_pwm $fan_cpu
enable_pwm $fan_gpu

# set fans at max to signal script is working
write_to $fan_case 200
write_to $fan_cpu 200
write_to $fan_gpu 200
sleep 3s

# Initialize temps and hysterisis temps
cput=$(get_cpu_temp)
gput=$(get_gpu_temp)
hyst_cput="$cput"
hyst_gput="$gput"

while true
do 
	# update temp values 
	cput=$(get_cpu_temp)
	gput=$(get_gpu_temp)
	
	# Update hysterisis temp values, if temps :
	# (1) increased or (2) dropped at least of $hysterisis celsius
	if [ $cput -gt $hyst_cput ] || [ $(($cput + $hysterisis)) -le $hyst_cput ]; then
		hyst_cput=$cput
	fi
	if [ $gput -gt $hyst_gput ] || [ $(($gput + $hysterisis)) -le $hyst_gput ]; then
		hyst_gput=$gput
	fi
	
	## Legacy "linearily mapped" speeds
	# map temp value to [0-255] rpm value
	#case_fanspeed_hex=$(interval_to_hex $cpu_idle_temp $cpu_max_temp $hyst_cput $fan_case_min_hex)
	#cpu_fanspeed_hex=$(interval_to_hex $cpu_idle_temp $cpu_max_temp $hyst_cput $fan_cpu_min_hex)
	#gpu_fanspeed_hex=$(interval_to_hex $gpu_idle_temp $gpu_max_temp $hyst_gput $fan_gpu_min_hex)
	
	# curve based speeds
	cpu_fanspeed=$(query_curve cpu_fan_curve_temps cpu_fan_curve_speeds $hyst_cput);
	gpu_fanspeed=$(query_curve gpu_fan_curve_temps gpu_fan_curve_speeds $hyst_gput);
	case_fanspeed=$cpu_fanspeed;
	cpu_fanspeed_hex=$(percent_to_hex $cpu_fanspeed $fan_cpu_min_hex);
	gpu_fanspeed_hex=$(percent_to_hex $gpu_fanspeed $fan_gpu_min_hex);
	case_fanspeed_hex=$cpu_fanspeed_hex;
	
	# Set fan speeds
	write_to $fan_case $case_fanspeed_hex
	write_to $fan_cpu $cpu_fanspeed_hex
	write_to $fan_gpu $gpu_fanspeed_hex
	
	# Feedback to user
	if [ $verbose ]
	then
		printf "\033c"
		echo '' 
		echo "  CPU temp : $cput  --  hyst : $hyst_cput"
		echo "  GPU temp : $gput  --  hyst : $hyst_gput"
		echo ""
		echo "  setting GPU  fan to $gpu_fanspeed % - $gpu_fanspeed_hex  [$fan_gpu_min_hex-255]"
		echo "  setting CPU  fan to $cpu_fanspeed % - $cpu_fanspeed_hex  [$fan_cpu_min_hex-255]"
		echo "  setting CASE fan to $case_fanspeed % - $case_fanspeed_hex  [$fan_case_min_hex-255]"
		echo ""
		echo "$(( ( RANDOM % 10 )  + 1 ))" # random number printed to show refreshes
	fi	
	
	# Wait until next cycle
	sleep "$refresh_interval"
done













########################################################################
## Unused helpers
##

#	Maps a percentage value to [0-255]
#		$1 		value to map
function _old_percent_to_hex
{	
	if [ "$1" -ge 100 ] || [ "$1" -le 0 ]
	then
		res=255
	else 
		# linear interpolation
		res=$(expr $1 \* 255 \/ 100)
	fi
	echo $res
}


