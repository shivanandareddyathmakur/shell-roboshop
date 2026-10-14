#!/bin/bash
USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
START_TIME=$(date +%s)
MONGODB_HOST=mongodb.reddy25.shop
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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installed nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$LOG_FILE
    VALIDATE $? "created system user"
else
    echo -e "user already exists....$Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$LOG_FILE
VALIDATE $? "downloading user application"

cd /app 
VALIDATE $? "changing to app directory"

rm -rf /app/*
unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unzipped user"

npm install  &>>$LOG_FILE
VALIDATE $? "installed dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "creating user service"

systemctl daemon-reload

systemctl enable user   &>>$LOG_FILE
VALIDATE $? "enabling user"

systemctl start user
VALIDATE $? "starting user"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "script executed in : $Y $TOTAL_TIME seconds $N"
