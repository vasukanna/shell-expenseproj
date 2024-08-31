#!/bin/bash

LOG_FOLDER="expense-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIME_STAMP=$(date +%Y-%m-%d-%H)
LOG_FILE=$LOG_FOLDER/$SCRIPT_NAME-$TIME_STAMP.log
mkdir -p expense-script

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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabled existed nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installed nodejs"

echo "adding user expense"
if [ $? -ne 0 ]
then
    echo -e "user not added ..$Y ..adding user $N"
    useradd expense
    VALIDATE $? "user adding"
else
    echo -e "already added user $Y skipping now $N"
fi

mkdir -p /app

cd /app
curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "downloading application"

rm -rf /app*
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "extracting backend application"

npm install &>>$LOG_FILE
VALIDATE $? "npm installed"

cp  /home/ec2-user/shell-expenseproj/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "insatll mysql"

mysql -h 172.31.41.165 -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "loading schema"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reload backend"

systemctl start backend &>>$LOG_FILE
VALIDATE $? "start backend"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "enable backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "restart backend"



