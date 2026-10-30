#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/logs/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_PATH=$PWD
START_TIME=$(date +%s)
LOG_FILE=$LOGS_FOLDER/$SCRIPT_NAME.log

echo "Script started excuted at: $(date)"

mkdir -p $LOGS_FOLDER

if [ $USERID -ne 0 ]; then
    echo "ERROR.. please run with root privelege"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e " $2 ... $R FAILURE $N " | tee -a $LOG_FILE
        exit 1
    else
        echo -e " $2 ... $G SUCCESS $N "| tee -a $LOG_FILE
    fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "installing python"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    echo "user already exists"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip
VALIDATE $? "downloading payment application"

cd /app 
VALIDATE $? "moving to app directory"

rm -rf /app/*

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzipping payment.zip"

cd /app 

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "installing packages"

cp $SCRIPT_PATH/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload

systemctl enable payment 
systemctl start payment