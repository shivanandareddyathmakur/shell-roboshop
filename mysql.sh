#!/bin/bash
USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +%s)
mkdir -p $LOGS_FOLDER

echo "script started ececuted at: $(date)" | tee -a $LOG_FILE #&>>$LOG_FILE only in logs

if [ $USER_ID -ne 0 ]; then
    echo -e "$R ERROR $N:: please run this script with root privelege"
    exit 1 #failure is other than 0
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R failed $N" | tee -a $LOG_FILE
        #exit 1 - if you want to dont continue when an failure occurs
    else 
        echo -e "$2 ... $G success $N"
    fi
}

dnf install mysql-server -y
VALIDATE $? "installing mysql-server"

systemctl enable mysqld
VALIDATE $? "enabling mysqld"

systemctl start mysqld  
VALIDATE $? "starting mysqld"

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "setting root password"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "script executed in : $Y $TOTAL_TIME seconds $N"

