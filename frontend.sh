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
        echo -e "$2 is ... $R FAILED $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is...$G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

ROOT_CHECK

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "install nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "enabled nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "started nginx"

rm -rf /usr/share/nginx/html/*

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATE $? "downloading code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "extrating code"

cp /home/ec2-user/shell-expenseproj/expense.conf /vim /etc/nginx/default.d/expense.conf

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restart nginx"
