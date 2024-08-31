#!/bin/bash

LOG_FOLDER="/var/log/expense-script"
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
        echo -e "$2 is ...$R FAILED $N" | tee -a &>>$LOG_FILE
        exit1
    else
        echo -e "$2 is ...$G SUCCESS $N " | tee -a &>>$LOG_FILE
    fi
}

ROOT_CHECK

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "installing mysql"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "enabling mysql"

systemctl start mysqld &>>LOG_FILE
VALIDATE $? "started mysql"

mysql -h 172.31.41.165 -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE
if [ $? -ne 0 ]
then 
    echo -e "please set up ..$R mysql root password $N"
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATE $? "mysql paswwordsetting"
else
    echo -e "already set the password $Y..skipping $N" | tee -a $LOG_FILE
fi



