#!/bin/bash

# Requirements:
#   create tmp dir
#   start screen with 2 windows, one for each miner. launch your miners
#   setup your own telegram bot via botfather, get the token
#   query your bot to get the chat id
#   create your own cron job (crontab)

hostname > /home/$USER/tmp/reporting
echo "-------------------------" >> /home/$USER/tmp/reporting
sensors >> /home/$USER/tmp/reporting
echo "-------------------------" >> /home/$USER/tmp/reporting
if command -v nvidia-smi &> /dev/null
then
    nvidia-smi | grep -B1 "Default" >> /home/$USER/tmp/reporting
    echo "-------------------------" >> /home/$USER/tmp/reporting
fi
screen -S `ls /run/screen/S-$USER/` -p 0 -X hardcopy /home/$USER/tmp/0
screen -S `ls /run/screen/S-$USER/` -p 1 -X hardcopy /home/$USER/tmp/1
tail -n 10 /home/$USER/tmp/0 >> /home/$USER/tmp/reporting
echo "-------------------------" >> /home/$USER/tmp/reporting
tail -n 10 /home/$USER/tmp/1 >> /home/$USER/tmp/reporting
echo "-------------------------" >> /home/$USER/tmp/reporting
curl -s -o /dev/null -d chat_id=<chat id> -d text="`cat /home/$USER/tmp/reporting`"  https://api.telegram.org/bot<token>/sendMessage