#!bin/bash

BASEDIR=`pwd`
TASKDIRS="pretask task1 task2 task3 task4 task5 task6"
KEY1="phong"
KEY2="tone"


for ts in ${TASKDIRS}
do
    echo -e "replace keyword \"${KEY1}\" to \"${KEY2}\" for ${ts}..."
    sed -i 's/'${KEY1}'/'${KEY2}'/g' ${BASEDIR}/${ts}/*.{cpp,h}
done

