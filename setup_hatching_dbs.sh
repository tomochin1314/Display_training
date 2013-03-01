#!/bin/bash
#this script is to set up by building the seeding method study; 

BASEDIR=`pwd`
SRCDIR=${BASEDIR}/src
BINDIR=${BASEDIR}/bin
DATADIR=${BASEDIR}/data
EXECUTABLES="singleitr multiviewitr multiwindowitr"
TECHS=${1:-"hatching_dbs"}
TASKDIRS=${1:-"pretask task1 task2 task3 task4 task5 task6"}

if [ ! -d ${SRCDIR} ];then
	echo "FATAL: directory ${SRCDIR} NOT found."
	exit -1
fi

#build executables for each of the tasks and set them up in task-wise
#sub-directories under the $BIN directory

mkdir -p ${BINDIR} ${DATADIR}

for tc in ${TECHS}
do
    for ts in ${TASKDIRS}
    do
        echo -e "building for ${ts} of ${tc}..."
        mkdir -p ${BINDIR}/${tc}/${ts}

        if [ ! -d ${SRCDIR}/${tc}/${ts} ];then
            echo "FATAL: sub-directory ${SRC}/${tc}/${ts} NOT found."
            rm -rf ${BINDIR}/*
            exit -1
        fi

        cp ${SRCDIR}/${tc}/${ts}/*.{h,cpp} ${SRCDIR}
        make -C ${SRCDIR} -w -f Makefile_${tc} all

        for bin in ${EXECUTABLES}
        do
            if [ ! -s ${SRCDIR}/${bin}_${tc} ];then
                echo "ERROR: executable ${SRCDIR}/${bin}_${tc} for ${ts} of ${tc} failed to be built."
                rm -rf ${BINDIR}/*
                exit -1
            fi

            mv -f ${SRCDIR}/${bin}_${tc} ${BINDIR}/${tc}/${ts}
        done
        make -C ${SRCDIR} -w -f Makefile_${tc} cleanall

        cp ${SRCDIR}/${tc}/${ts}/{tasktext,helptext} ${BINDIR}/${tc}/${ts}

        echo -e "\t\t------ finished."
    done

    echo -e "\t\t------ ${tc} finished."
done

echo -e "\n\t---- setup completed ----\t\n"

exit 0

