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
MYSQL_HOST=mysql.reddy25.shop
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

dnf install maven -y &>>$LOG_FILE

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir /app 

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 

cd /app 

unzip /tmp/shipping.zip

cd /app 

mvn clean package 

mv target/shipping-1.0.jar shipping.jar 

vim /etc/systemd/system/shipping.service

systemctl daemon-reload

systemctl enable shipping 

systemctl start shipping

dnf install mysql -y 

mysql -h $MYSQL_HOST -uroot -pRoboshop@1 -e "use cities"

if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
else
    echo -e "shipping data is already loaded....$Y SKIPPING $N"
fi

systemctl restart shipping


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "script executed in : $Y $TOTAL_TIME seconds $N"