#!/bin/bash

LOG_FOLDER="/var/log/expense-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIME_STAMP=$(date +%Y-%m-%d-%H)
LOG_FILE=$LOG_FOLDER/$SCRIPT_NAME-$TIME_STAMP.log

mkdir -p $LOG_FOLDER

R="\e[31m"
G="\e[32m"
N="\e[0"
Y="\e[33"

USER_ID=$(id -u)

ROOT_CHECK(){
    if [ $USER_ID -ne 0 ]
    then
        echo -e "please run the script with ..$R root privillages $N"
        exit 1
   fi 
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is ...$R FAILED $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ...$G SUCCESS $N " | tee -a $LOG_FILE
    fi
}

ROOT_CHECK

dnf module disable nodejs -y 
VALIDATE $? "disabled existed nodejs"

dnf module enable nodejs:20 -y 
VALIDATE $? "enable nodejs20"

dnf install nodejs -y 
VALIDATE $? "installed nodejs"

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "user not added ..$G ..ADDING USER $N"
    useradd expense 
    VALIDATE $? "user adding"
else
    echo -e "already added user $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "creating app"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "downloading application"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip 
VALIDATE $? "extracting backend application"

npm install 
#pwd
cp /home/ec2-user/shell-expenseproj/backend.service /etc/systemd/system/backend.service

dnf install mysql -y 
VALIDATE $? "insatll mysql" 

mysql -h 172.31.41.165 -uroot -pExpenseApp@1 < /app/schema/backend.sql 
VALIDATE $? "loading schema"

systemctl daemon-reload 
VALIDATE $? "reload backend"

systemctl start backend 
VALIDATE $? "start backend"

systemctl enable backend 
VALIDATE $? "enable backend"

systemctl restart backend 
VALIDATE $? "restart backend"



