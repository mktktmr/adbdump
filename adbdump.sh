#!/bin/sh

#= define constants ==========================================================>
#interval time to get dump (seconds)
INTERVAL=1
#application name
APP_NAME='jp.co.hoge'
#log's column separator
SEPARATOR='\t'
#log file name
LOG_FILE_NAME='dumpsys.log'
#log's header
LOG_HEADER='datetime'"$SEPARATOR"'CPU usage (%)'"$SEPARATOR"'memory allocate (kB)'

#= define function ===========================================================>
# to print for debug
debug () {
    echo debug: "$1""$2"
}

# to print for error
error () {
    echo error: "$1""$2"
}

# to print for info
info () {
    echo info: "$1""$2"
}

#= main =======================================================================>

#check to install android-sdk and to export PATH to sdk
if [ ! -n `which adb` ]; then
    info 'install android-sdk and export PATH to sdk'
    exit 1
fi

#check to exist a device
ps_list=`adb shell ps`
if [ $? -ne 0 ]; then
    exit 1
fi

#check exist file and delete file
if [ -f "$LOG_FILE_NAME" ]; then
    rm "$LOG_FILE_NAME"
fi

# wirte log header
echo "$LOG_HEADER" >> "$LOG_FILE_NAME"

#get pid
pid=`echo "$ps_list" | grep "$APP_NAME" | awk '{ print $2 }'`

info 'logging is processing.'
info 'You can stop logging to enter <C+c>.'

while [ 0 ]
do
    #アプリ生死判定
    if [ `adb shell ps "$pid" | wc -l` -ne 2 ]; then
        # プロセスが存在すれば、psコマンドでヘッダ含め２行出力される
        error 'app is killed'
        error 'logging is stoped for error'
        error 'app is killed' >> "$LOG_FILE_NAME"
        exit 1
    fi
    
    (
        #get date
        if [ -n `which gdate` ]; then
            date=`gdate +"%Y-%m-%d %H:%M:%S.%3N"`
        else
            date=`date +"%Y-%m-%d %H:%M:%S"`
        fi

        #get meminfo
        meminfo=`adb shell dumpsys meminfo "$APP_NAME" | grep 'Dalvik Heap' |
        awk '{
            if(NF==9){ print $8 }
        }'`
        
        #get cpuinfo
        cpuinfo=`adb shell dumpsys cpuinfo | grep "$APP_NAME" | awk '{ print $1}'`
        if [ -n "$cpuinfo" ]; then
            cpuinfo=`echo "$cpuinfo" | sed 's/+//' | sed 's/%//'`
        else
            cpuinfo='0'
        fi

        echo ["$date"]"$SEPARATOR""$cpuinfo""$SEPARATOR""$meminfo" >> "$LOG_FILE_NAME"
    )&
    
    sleep "$INTERVAL"
done

exit 0
