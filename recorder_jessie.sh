#!/bin/bash
#
# Install gpac yad
# Do 'echo "bash ~/beecam/recorder_jessie.sh" >> ~/.profile'
# Install SD card from here: https://spotpear.com/index/study/detail/id/141.html
### Do 'sudo nano /etc/apt/sources.list' and uncomment 'deb-src ...'
### Do 'sudo nano /etc/apt/apt.conf.d/10defaultRelease' and replace 'stable' with 'stretch'
### To  deisable bluetooth and wifi, add this to '/boot/config.txt':
### dtoverlay=pi3-disable-wifi
### dtoverlay=pi3-disable-bt
## Disable screensaved by editing /etc/lightdm/lightdm.conf and replacing
## "xserver-command=X" with "xserver-command=X -s 0 -p 0 -dpms"

# Edit for video settings

video_width=1280
video_height=720
rotation_degrees=180
fps=50
saturation=-100 # For black and white use -100. default is 0
exposure_mode="auto"

# video_width=1920 video_height=1080
# fps=90 video_width=640 video_height=480

bitrate=10000000

convert_to_mp4=true
mp4_fps=$fps

# Edit for file numbering
count_from=1000

### Create "times" file for counting if does not exist
create_timer_file () {
        echo $((60)) > timer
        echo $((30)) >> timer
        echo $((10)) >> timer
        echo $((30)) >> timer
}

if [ -f timer ]; then
    echo "Timer file exists."
# Check if the file is 4 lines long
    if [ $(wc -l < timer) -eq 4 ]; then
        echo "Timer file is three lines long."
    else
        echo "count file is not two lines long. Creating ..."
        create_timer_file
    fi
else
    echo "count file does not exist. Creating ..."
    create_timer_file
fi

TIMERN=$(sed -n '1p' timer)
VIDN=$(sed -n '2p' timer)
REPEATN=$(sed -n '3p' timer)
SLEEP_TIME=$(sed -n '4p' timer)
VID_DIR=$HOME/Videos

countn () {
    FNUMBER=$(< count)
    FNUMBER=$((FNUMBER + 1))
    echo ${FNUMBER} > count
    export FNUMBER
}

record_video () {
    sleep 5 && python3 /home/pi/beecam/led.py & \
    VLENGTH=$((ans * 60000))
    yad --timeout-indicator=top --posx=90 --posy=245 --text-align=center \
    --timeout=$((ans * 60 + 5)) \
    --text="<big><b><span color='red'>${FILENAME}.h264</span></b></big>" \
    --button="<big><big><b>Cancel video recording</b></big></big>:killall raspivid & killall yad & exit"  & \

raspivid -t ${VLENGTH} -b ${bitrate} -sa ${saturation} -ex ${exposure_mode} -fps ${fps} -rot ${rotation_degrees} -w ${video_width} -h ${video_height} -p 0,0,480,245 \
 -o ${VID_DIR}/${FILENAME}.h264

}

convert_video () {
    yad --info --center --text="<big><big><big><b>\nConverting to mp4.\n\n<span color='red'>${FILENAME}.h264</span>\n\nPlease wait...</b></big></big></big>" --no-buttons --text-align=center --borders=20 &\
    MP4Box -add ${VID_DIR}/${FILENAME}.h264:fps=${mp4_fps} ${VID_DIR}/${FILENAME}.mp4 && killall yad
    # yad --info --center --text "<big><big><big><big>Video converted to \n\n<span color='red'><b>${FILENAME}.mp4</b></span></big></big></big></big>" \
    #     --title="Info" --text-align=center \
    #     --button="<big><big><big><big>OK</big></big></big></big>:killall yad" --borders=20
    echo "Coverted to mp4"
}
export -f record_video

set_timer () {
# Read the count file by line:
    array=($(yad \
        --item-separator="," --separator="\\n" --form --columns 1 --center --borders=20 \
        --field="<big><b>Delay before first recording (min)</b></big>":NUM $TIMERN,0..1000,1 \
        --field="<big><b>Video length (min)</b></big>":NUM $VIDN,1..1000,1 \
        --field="<big><b>Repeat (times)</b></big>":NUM $REPEATN,1..1000,1 \
        --field="<big><b>Delay between videos (min)</b></big>":NUM $SLEEP_TIME,0..1000,1 \
        ))
    TIMERN=${array[0]}
    VIDN=${array[1]}
    REPEATN=${array[2]}
    SLEEP_TIME=${array[3]}
    declare -p array
    if true; then
        echo "Remembering timer value"
        echo $TIMERN > timer
        echo $VIDN >> timer
        echo $REPEATN >> timer
        echo $SLEEP_TIME >> timer
    else
        echo "Not remembering timer value"
    fi
export TIMERN
export VIDN
export REPEATN
timer_window
}
export -f set_timer

timer_window () {
        ans2=$(yad  --center --borders=20 --text="<big><b>Delay before first recording: <span color='red'>${TIMERN}</span> minutes.\\nVideo length: ${VIDN} minutes. \
        \\nWill be recorder ${REPEATN} times and \\n${SLEEP_TIME} minute delay between videos.</b></big>" \
                --button="Cancel":0 --button="Change settings":1 --button="Start recording":2)
        ans2=$?
        export TIMERN
        export VIDN
        export REPEATN
        export SLEEP_TIME
        echo $ans2
        if [[ $ans2 == 1 ]]; then
            set_timer
        elif [[ $ans2 == 2 ]]; then
            # Show timeout indicator
            $(yad --timeout-indicator=top --posx=90 --posy=245 --text-align=center  --center --borders=20  \
            --timeout=$((TIMERN * 60 + 1)) \
            --text="<big><big><b>Waiting for ${TIMERN} minutes</b></big></big>" \
            --button="<big><big><b>Cancel video recording</b></big></big>:0")
            ans3=$?
            echo ${ans3}
            
            if [[ $ans3 == 0 ]]; then
                main
                break
            fi
            echo "Timer finished"
            DATE=`date +%s`
            ans=$VIDN
            export ans
            echo $ans
            rm videos
            for (( c=1; c<=$REPEATN; c++ )); do
                countn
                echo $c
                DATE1=`date +%s`
                TIMESTAMP=$((DATE1-DATE))
                FILENAME=bees_${FNUMBER}_${c}_of_${REPEATN}_${TIMESTAMP}
                export FILENAME
                echo ${FILENAME} >> videos
                export TIMESTAMP
                echo "Recording video $c of $REPEATN"
                record_video
                # Sleep between videos, but not after the last one
                if [[ $c -lt $REPEATN ]]; then
                    echo "Sleeping for $SLEEP_TIME minutes"
                    sleep $((SLEEP_TIME * 60))
                fi
            done
            for video in $(cat videos); do
                echo "Converting $video"
                FILENAME=$video
                export FILENAME
                convert_video
            done
            rm videos
            killall yad
            main
            break
        else
            main
            break
        fi
}

export -f timer_window

main () {
while true; do
  ans=$(zenity --info --title 'Record a video' \
      --text 'Choose video duration in minutes' \
      --ok-label Quit \
      --extra-button "Timer" \
      --extra-button 30 \
      --extra-button "Photo" \
      --extra-button "Focus" \
       )

### Quit if "Quit" is pressed
re='^[0-9]+$'
export ans
if ! [[ $ans =~ $re ]] ; then
    if [[ $ans = "Focus" ]] ; then
        raspivid -t 100000 -w 1920 -h 1080 -rot ${rotation_degrees} --roi 0.6,0.5,0.25,0.25 -p 0,0,480,270 & \
        yad --info --timeout=100 --posy=273 \
            --button="<big><big><big><b>Close this window</b></big></big></big>":"killall raspivid & killall yad" \
            --button="<big><big><big><b>Rotate</b></big></big></big>":
            # read file "rotation":
            rotation_degrees=$(< rotation)
            if [[ $rotation_degrees = 0 ]]; then
                rotation_degrees=180
            else
                rotation_degrees=0
            fi
            echo ${rotation_degrees} > rotation
            killall raspivid
        main
        break
    elif [[ $ans = "Photo" ]] ; then
        FNUMBER=$(< count)
        FNUMBER=$((FNUMBER + 1))
        echo ${FNUMBER} > count
        raspistill -sa -100 -t 10800000000 -tl 10000 -p 0,0,370,245 -rot ${rotation_degrees} -o ~/Pictures/image${FNUMBER}_%04d.jpg & \
        yad --info --posy=273 \
            --button="<big><big><big><b>Cancel</b></big></big></big>":"killall raspistill & killall yad"
        main
        break
    elif [[ $ans = "Timer" ]] ; then
        timer_window
        break
    else
        break
    fi
fi

### Create "count" file for counting if does not exist
if [ -f count ]; then
    echo "count file exists."
else
    echo "count file does not exist. Creating ..."
    echo ${count_from} > count
fi

VLENGTH=$((ans * 60000))
# echo ${VLENGTH} > ans
countn
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME=bees_${FNUMBER}_${TIMESTAMP}
export FILENAME
record_video
if $convert_to_mp4 ; then
convert_video
fi
done
}

export -f main

while true; do
    main
    yad --info --center --borders=20 \
        --button="<big><big><big><big><b>Poweroff</b></big></big></big></big>":"poweroff" \
        --button="<big><big><big><big>Back</big></big></big></big>"       
done
