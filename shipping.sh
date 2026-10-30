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
MONGODB_HOST=mongodb.reddy25.shop
MYSQL_HOST=mysql.reddy25.shop

echo "Script started excuted at: $(date)"

mkdir -p $LOGS_FOLDER

if [ $USERID -ne 0 ]; then
    echo "ERROR.. please run with root privelege"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e " $2 ... $R FAILURE $N "
        exit 1
    else
        echo -e " $2 ... $G SUCCESS $N "
    fi
}

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "installing maven"

id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "creating system user"
    else
        echo -e "system user already exists $Y SKIPPING $N"
    fi

mkdir -p /app  &>>$LOG_FILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "downloading shipping application"

cd /app 
VALIDATE $? "moving to app directory"

rm -rf /app/*
VALIDATE $? "clearing old apps in app directory"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping shipping"

mvn clean package  &>>$LOG_FILE
mv target/shipping-1.0.jar shipping.jar  &>>$LOG_FILE

cp $SCRIPT_PATH/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "copying shipping.service"

systemctl daemon-reload
systemctl enable shipping 

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "installing mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping


