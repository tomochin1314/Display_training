#!/bin/bash

SRCDIR=`pwd`
TASKDIRS=${1:-"pretask task1 task2 task3 task4 task5 task6"}

SRCFILE=situbeRenderPhong
DSTFILES=${1:-"situbeRenderPhongHalo situbeRenderTone situbeRenderToneHalo 
               situbeRenderHatching situbeRenderHatchingHalo situbeRenderAO situbeRenderAOHalo"}


SRCFILE_MV=mitubeRenderViewPhong
DSTFILES_MV=${1:-"mitubeRenderViewPhongHalo mitubeRenderViewTone mitubeRenderViewToneHalo
                 mitubeRenderViewHathcing mitubeRenderViewHathcingHalo mitubeRenderViewAO
                 mitubeRenderViewAOHalo"}

SRCFILE_MW=mitubeRenderWindowPhong
DSTFILES_MW=${1:-"mitubeRenderWindowPhongHalo mitubeRenderWindowTone mitubeRenderWindowToneHalo
                 mitubeRenderWindowHatching mitubeRenderWindowHatchingHalo
                 mitubeRenderWindowAO mitubeRenderWindowAOHalo"}

SRCMAINFILE=singleitr_phong
DSTMAINFILES=${1:-"singleitr_phong_halo singleitr_tone singleitr_tone_halo singleitr_hatching
                   singleitr_hatching_halo singleitr_ao singleitr_ao_halo"}

SRCMAINFILE_MV=multiviewitr_phong
DSTMAINFILES_MV=${1:-"multiviewitr_phong_halo multiviewitr_tone multiviewitr_tone_halo
                     multiviewitr_hatching multiviewitr_hatching_halo multiviewitr_ao
                     multiviewitr_ao_halo"}

SRCMAINFILE_MW=multiwindowitr_phong
DSTMAINFILES_MW=${1:-"multiwindowitr_phong_halo multiwindowitr_tone multiwindowitr_tone_halo
                     multiwindowitr_hatching multiwindowitr_hatching_halo multiwindowitr_ao
                     multiwindowitr_ao_halo"}


# for situbeRender in src directory
for df in ${DSTFILES}
do
    mkdir ${SRCDIR}/temp
    cp -n ${SRCDIR}/${SRCFILE}.* ${SRCDIR}/temp
    rename ${SRCDIR}/temp/${SRCFILE}. ${SRCDIR}/temp/${df}. ${SRCDIR}/temp/*.*
    cp -n ${SRCDIR}/temp/${df}.* ${SRCDIR}
    rm -r ${SRCDIR}/temp

    # change include file name in this file
    sed -i "s/${SRCFILE}/${df}/g" ${SRCDIR}/${df}.cpp

done



# for mitubeRender in src directory
for df in ${DSTFILES_MV}
do
    mkdir ${SRCDIR}/temp
    cp -n ${SRCDIR}/${SRCFILE_MV}.* ${SRCDIR}/temp
    rename ${SRCDIR}/temp/${SRCFILE_MV}. ${SRCDIR}/temp/${df}. ${SRCDIR}/temp/*.*
    cp -n ${SRCDIR}/temp/${df}.* ${SRCDIR}
    rm -r ${SRCDIR}/temp


    # change include file name in this file
    sed -i "s/${SRCFILE_MV}/${df}/g" ${SRCDIR}/${df}.cpp
done


for df in ${DSTFILES_MW}
do
    mkdir ${SRCDIR}/temp
    cp -n ${SRCDIR}/${SRCFILE_MW}.* ${SRCDIR}/temp
    rename ${SRCDIR}/temp/${SRCFILE_MW}. ${SRCDIR}/temp/${df}. ${SRCDIR}/temp/*.*
    cp -n ${SRCDIR}/temp/${df}.* ${SRCDIR}
    rm -r ${SRCDIR}/temp

    # change include file name in this file
    sed -i "s/${SRCFILE_MW}/${df}/g" ${SRCDIR}/${df}.cpp
done





# for main files
for df in ${DSTMAINFILES}
do
    mkdir ${SRCDIR}/temp
    cp -n ${SRCDIR}/${SRCMAINFILE}.* ${SRCDIR}/temp
    rename ${SRCDIR}/temp/${SRCMAINFILE}. ${SRCDIR}/temp/${df}. ${SRCDIR}/temp/*.*
    cp -n ${SRCDIR}/temp/${df}.* ${SRCDIR}
    rm -r ${SRCDIR}/temp

done

for df in ${DSTMAINFILES_MV}
do
    mkdir ${SRCDIR}/temp
    cp -n ${SRCDIR}/${SRCMAINFILE_MV}.* ${SRCDIR}/temp
    rename ${SRCDIR}/temp/${SRCMAINFILE_MV}. ${SRCDIR}/temp/${df}. ${SRCDIR}/temp/*.*
    cp -n ${SRCDIR}/temp/${df}.* ${SRCDIR}
    rm -r ${SRCDIR}/temp


    # change include file name in this file
    sed -i "s/${SRCFILE_MV}/${df}/g" ${SRCDIR}/${df}.cpp
done

for df in ${DSTMAINFILES_MW}
do
    mkdir ${SRCDIR}/temp
    cp -n ${SRCDIR}/${SRCMAINFILE_MW}.* ${SRCDIR}/temp
    rename ${SRCDIR}/temp/${SRCMAINFILE_MW}. ${SRCDIR}/temp/${df}. ${SRCDIR}/temp/*.*
    cp -n ${SRCDIR}/temp/${df}.* ${SRCDIR}
    rm -r ${SRCDIR}/temp


    # change include file name in this file
    sed -i "s/${SRCFILE_MW}/${df}/g" ${SRCDIR}/${df}.cpp
done



# for situbeRender and mitubeRender in task directory
for ts in ${TASKDIRS}
do
    for df in ${DSTFILES}
    do
        mkdir ${SRCDIR}/${ts}/temp
        cp -n ${SRCDIR}/${ts}/${SRCFILE}.* ${SRCDIR}/${ts}/temp
        rename ${SRCDIR}/${ts}/temp/${SRCFILE}. ${SRCDIR}/${ts}/temp/${df}. ${SRCDIR}/${ts}/temp/*.*
        # change include file name in this file
        sed -i "s/${SRCFILE}/${df}/g" ${SRCDIR}/${ts}/temp/${df}.cpp
        cp -n ${SRCDIR}/${ts}/temp/${df}.* ${SRCDIR}/${ts}
        rm -r ${SRCDIR}/${ts}/temp
    done

    if [ $ts = "task6" ];then

        for df in ${DSTFILES_MV}
        do
            mkdir ${SRCDIR}/${ts}/temp
            cp -n ${SRCDIR}/${ts}/${SRCFILE_MV}.* ${SRCDIR}/${ts}/temp
            rename ${SRCDIR}/${ts}/temp/${SRCFILE_MV}. ${SRCDIR}/${ts}/temp/${df}. ${SRCDIR}/${ts}/temp/*.*
            cp -n ${SRCDIR}/${ts}/temp/${df}.* ${SRCDIR}/${ts}
            rm -r ${SRCDIR}/${ts}/temp

            # change include file name in this file
            sed -i "s/${SRCFILE_MV}/${df}/g" ${SRCDIR}/${ts}/${df}.cpp
            echo "${SRCFILE_MV}, ${SRCDIR}/${ts}/${df}.cpp"

        done
        for df in ${DSTFILES_MV}
        do
            # change include file name in this file
            sed -i "s/${SRCFILE}/${df}/g" ${SRCDIR}/${ts}/${df}.cpp
        done

    fi
done



