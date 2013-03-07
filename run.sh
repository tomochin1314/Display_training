
#this script, presuming that all executables and data have been readyed in the
#configurable directories as follows, boosts a run of the whole study of seeding
#methods in DTI tractography.
#--- this version is proprietarily written for formal seeding study.

BASEDIR=`pwd`

BINDIR=${BASEDIR}/bin
TASKDIRS="pretask task1 task2 task3 task4 task5 task6"
EXECUTABLES="singleitr multiviewitr multiwindowitr"

DATADIR=${BASEDIR}/data
ALLNORMALCASEDATADIRS="${DATADIR}/normal_whole ${DATADIR}/normal_allfb"
y=`expr $RANDOM % 100`
if [ $y -ge 50 ];then
	ALLNORMALCASEDATADIRS="${DATADIR}/normal_allfb ${DATADIR}/normal_whole"
fi

BUNDLES="cst cc ifo ilf"
FIBERBUNDLES=(cst cc ifo ilf)

LOG=${BASEDIR}/studylog

ORDERARRAY=()
NUMROW=0 #number of row in the order matrix
NUMCOL=0 #number of column in the order matrix
#FBARRARY=(cst cc ifo ilf)
CURORDER=""
CURFB=""

TASKPROGIDFILE=${BASEDIR}/taskprogidfile
TASKNO=0

TUBERADIUS="0.4"

function checkbins()
{
	if [ ! -d ${BINDIR} ];then
		echo "FATAL: directory ${BINDIR} NOT found, please set up firstly."
		return 1
	fi

	for ts in ${TASKDIRS}
	do
		for bin in ${EXECUTABLES}
		do
			if [ ! -s ${BINDIR}/${ts}/${bin} ];then
				echo "ERROR: executable ${bin} for ${ts} NOT found,"
			    echo "please set up firstly."
				return 1
			fi
		done
	done
	return 0
}

function checkdata()
{
	for NORMALCASEDATADIR in  ${ALLNORMALCASEDATADIRS}
	do
		for bdir in ${NORMALCASEDATADIR}
		#${ABNORMALCASEDATADIR}
		do
			if [ ! -d ${bdir} ];then
				echo "ERROR: data directory ${bdir} NOT found."
				return 1
			fi

			# ' now we totally discard the whole brain models
			#for ((n=1;n<=5;n++));do
				#if [ `ls ${bdir}/normal_s${n}.data | wc -l` -le 0 ];then
					#echo "ERROR: data of resolution ${n}x${n}x${n} NOT found in the"
					#echo "directory ${bdir}"
					#return 1
				#fi
			#done

			# check task-specific data
			for ts in ${TASKDIRS}
			do
				if [ $ts = "pretask" ];then
					continue
				fi

				taskdatadir="region_for_${ts}"
				for ((n=1;n<=5;n++));do
					for fb in ${BUNDLES}
					do
						# cc and ifo not used in task6
						if [ $ts = "task6" ];then
							if [ $fb = "cc" -o $fb = "ifo" ];then
								continue
							fi
						fi

						if [ `ls -R ${bdir}/${taskdatadir}/s${n}/${fb}/ | grep data | wc -l` -lt 2 ];then
							echo "ERROR: data missed for ${ts}/s${n}/${fb}."
							return 1
						fi
					done
				done
			done
		done
	done

	return 0
}

#$1 - task order text file
#$? - 0 for success and 1 otherwise

function readorder()
{
	if [ $# -lt 1 -o ! -s $1 ];then
		echo "In readorder: too few arguments or file does not exist."
		return 1
	fi

	#take the number of fields in the first line as the number of column  of
	#the matrix to read into

	local fldnum=0
	local currow=0
	#cat $1 | \
	while read curline
	do
		curfldnum=`echo $curline | awk '{print NF}'`
		if [ $fldnum -eq 0 ];then
			fldnum=$curfldnum
		elif [ $curfldnum -ne $fldnum ];then
			echo "inconsistent row - different number of columns."
			return 1
		fi

		local currol=0
		for num in $curline
		do
			let "index = $currow * $fldnum + $currol"
			ORDERARRAY[$index]=$num
			let "currol += 1"
		done

		let "currow += 1"

	done < $1

	let NUMROW=$currow
	let NUMCOL=$fldnum
	#echo "NUMCOL=$NUMCOL"
	#echo "NUMROW=$NUMROW"

	return 0
}

function print_order()
{
	echo ${ORDERARRAY[*]} | xargs -n $NUMCOL
}

function taskflag()
{
	echo -e "\n##############################################################" >> $LOG
	echo "                           TASK $1                            " >> $LOG
	echo -e "##############################################################\n" >> $LOG
}

function updatetaskprog()
{
	let "TASKNO += 1"
	echo -e "\n\n       $TASKNO / 600" > ${TASKPROGIDFILE}
}

#-----------------------------------------#
#
# pretask
#
#-----------------------------------------#
function pretask()
{
	#this is a trivial, actually virtual, task. It just show the introductory
	#message of the tasks to follow

	${BINDIR}/pretask/singleitr \
		-f ${NORMALCASEDATADIR}/region_for_task1/s1/cc/region_s1.data \
		-t ${BINDIR}/pretask/tasktext \
		-V 1>> $LOG 2>&1
}

#-----------------------------------------#
#
# task 1
#
#-----------------------------------------#
function task1()
{
	taskflag 1

    local halo=0
    local shadow=0
    local cst=0
    local cc=0
    local ifo=0
    local ilf=0

    for NORMALCASEDATADIR in  ${ALLNORMALCASEDATADIRS}
    do
        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )


        echo -e "\n##### with Normal case #####" >> $LOG
        echo "##### under seeding resolution of ${fixres}x${fixres}x${fixres} #####" >> $LOG

        for((i=0;i<48;++i))
        do
            updatetaskprog

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi

            if [ ${cst} -eq 1 ];then
                CURFB="cst"
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG

            ${BINDIR}/task1/singleitr \
                -f \
                ${NORMALCASEDATADIR}/region_for_task1/s${fixres}/${CURFB}/region_s${fixres}.data \
                -s \
                ${NORMALCASEDATADIR}/region_for_task1/s${fixres}/${CURFB}/skeleton_region_s${fixres}.data \
                -j \
                ${NORMALCASEDATADIR}/region_for_task1/s${fixres}/${CURFB}/tumorbox_0_region_s${fixres}.data \
                -j \
                ${NORMALCASEDATADIR}/region_for_task1/s${fixres}/${CURFB}/tumorbox_1_region_s${fixres}.data \
                -t ${BINDIR}/task1/tasktext \
                -p ${TASKPROGIDFILE} \
                -i ${flip} \
                -r ${TUBERADIUS} \
                -a ${halo} \
                -w ${shadow} \
                -q ${tec} \
                -V 1>> $LOG 2>&1

            if [ $? -ne 0 ];then
                return 3
            fi
    done
        echo -e "\n Technique complete...\n" >> $LOG


        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )

        echo -e "\n##### with Normal case #####" >> $LOG
        echo "##### under seeding resolution of ${fixres}x${fixres}x${fixres} #####" >> $LOG

        # the same participant does the second block of task data
        for((i=0;i<48;++i))
        do

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi

            if [ ${cst} -eq 1 ];then
                CURFB="cst"
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG

            ${BINDIR}/task1/singleitr \
                -f \
                ${NORMALCASEDATADIR}/region_for_task1/s${fixres}/${CURFB}/pos1/region_s${fixres}.data \
                -s \
                ${NORMALCASEDATADIR}/region_for_task1/s${fixres}/${CURFB}/pos1/skeleton_region_s${fixres}.data \
                -j \
                ${NORMALCASEDATADIR}/region_for_task1/s${fixres}/${CURFB}/pos1/tumorbox_0_region_s${fixres}.data \
                -j \
                ${NORMALCASEDATADIR}/region_for_task1/s${fixres}/${CURFB}/pos1/tumorbox_1_region_s${fixres}.data \
                -t ${BINDIR}/task1/tasktext \
                -p ${TASKPROGIDFILE} \
                -i ${flip} \
                -r ${TUBERADIUS} \
                -a ${halo} \
                -w ${shadow} \
                -q ${tec} \
                -V 1>> $LOG 2>&1

            if [ $? -ne 0 ];then
                return 3
            fi

        done
        echo -e "\n Technique complete...\n" >> $LOG

    done
    return 0
}

#-----------------------------------------#
#
# task 2 
#
#-----------------------------------------#
function task2()
{
    taskflag 2

    local keys1=(2 2 3 3 2)
    local keys2=(3 2 1 3 1)
    local keys3=(3 2 3 2 3)
    local keys4=(2 2 3 2 3)

    local halo=0
    local shadow=0
    local cst=0
    local cc=0
    local ifo=0
    local ilf=0


    #sfb=(cst cc ifo ilf)
    #dices=( $(echo "0 1 2 3" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )
    #FBARRARY=( ${sfb[${dices[0]}]} ${sfb[${dices[1]}]} ${sfb[${dices[2]}]} ${sfb[${dices[3]}]} )
    #echo "focus order:" ${FBARRARY[*]} >> $LOG

    for NORMALCASEDATADIR in  ${ALLNORMALCASEDATADIRS}
    do

        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )

        echo -e "\n##### with Normal case #####" >> $LOG
        echo "##### under seeding resolution of ${fixres}x${fixres}x${fixres} #####" >> $LOG

        for((i=0;i<48;++i))
        do
            updatetaskprog

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi

            if [ ${cst} -eq 1 ];then
                CURFB="cst"
                CURKEY=$(eval echo \${keys1[$((fixres-1))]})
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
                CURKEY=$(eval echo \${keys2[$((fixres-1))]})
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
                CURKEY=$(eval echo \${keys3[$((fixres-1))]})
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
                CURKEY=$(eval echo \${keys4[$((fixres-1))]})
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG

            ${BINDIR}/task2/singleitr \
                -f \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/region_s${fixres}.data \
                -s \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/skeleton_region_s${fixres}.data \
                -i \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/fiberidx_*_region_s${fixres}.data \
                -j \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/tumorbox_0_region_s${fixres}.data \
                -j \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/tumorbox_1_region_s${fixres}.data \
                -j \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/tumorbox_2_region_s${fixres}.data \
                -t ${BINDIR}/task2/tasktext \
                -k ${CURKEY} \
                -p ${TASKPROGIDFILE} \
                -r ${TUBERADIUS} \
                -a ${halo} \
                -w ${shadow} \
                -q ${tec} \
                -V 1>> $LOG 2>&1

            if [ $? -ne 0 ];then
                return 3
            fi
        done
        echo -e "\n Technique complete...\n" >> $LOG


        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )

        echo -e "\n##### with Normal case #####" >> $LOG
        echo "##### under seeding resolution of ${fixres}x${fixres}x${fixres} #####" >> $LOG

        # the same participant does the second block of task data
        for((i=0;i<48;++i))
        do
            updatetaskprog

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi

            if [ ${cst} -eq 1 ];then
                CURFB="cst"
                CURKEY=$(eval echo \${keys1[$((fixres-1))]})
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
                CURKEY=$(eval echo \${keys2[$((fixres-1))]})
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
                CURKEY=$(eval echo \${keys3[$((fixres-1))]})
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
                CURKEY=$(eval echo \${keys4[$((fixres-1))]})
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG

            ${BINDIR}/task2/singleitr \
                -f \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/pos1/region_s${fixres}.data \
                -s \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/pos1/skeleton_region_s${fixres}.data \
                -i \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/pos1/fiberidx_*_region_s${fixres}.data \
                -j \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/pos1/tumorbox_0_region_s${fixres}.data \
                -j \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/pos1/tumorbox_1_region_s${fixres}.data \
                -j \
                ${NORMALCASEDATADIR}/region_for_task2/s${fixres}/${CURFB}/pos1/tumorbox_2_region_s${fixres}.data \
                -t ${BINDIR}/task2/tasktext \
                -k ${CURKEY} \
                -p ${TASKPROGIDFILE} \
                -r ${TUBERADIUS} \
                -a ${halo} \
                -w ${shadow} \
                -q ${tec} \
                -V 1>> $LOG 2>&1

            if [ $? -ne 0 ];then
                return 3
            fi
        done
        echo -e "\n Technique complete...\n" >> $LOG
    done
    return 0
}

#-----------------------------------------#
#
# task 3 
#
#-----------------------------------------#
function task3()
{
    taskflag 3

    #sfb=(cst cc ifo ilf)
    #dices=( $(echo "0 1 2 3" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )
    #FBARRARY=( ${sfb[${dices[0]}]} ${sfb[${dices[1]}]} ${sfb[${dices[2]}]} ${sfb[${dices[3]}]} )
    #echo "focus order:" ${FBARRARY[*]} >> $LOG


    local halo=0
    local shadow=0
    local cst=0
    local cc=0
    local ifo=0
    local ilf=0


    for NORMALCASEDATADIR in  ${ALLNORMALCASEDATADIRS}
    do

        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )

        echo -e "\n##### with Normal case #####" >> $LOG
        echo "##### under seeding resolution of ${fixres}x${fixres}x${fixres} #####" >> $LOG

        for((i=0;i<48;++i))
        do
            updatetaskprog

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi

            if [ ${cst} -eq 1 ];then
                CURFB="cst"
                CURKEY=1
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
                CURKEY=2
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
                CURKEY=3
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
                CURKEY=4
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG

            ${BINDIR}/task3/singleitr \
                -f \
                ${NORMALCASEDATADIR}/region_for_task3/s${fixres}/${CURFB}/region_s${fixres}.data \
                -s \
                ${NORMALCASEDATADIR}/region_for_task3/s${fixres}/${CURFB}/skeleton_region_s${fixres}.data \
                -i \
                ${NORMALCASEDATADIR}/region_for_task3/s${fixres}/${CURFB}/fiberidx_*_region_s${fixres}.data \
                -p ${TASKPROGIDFILE} \
                -r ${TUBERADIUS} \
                -k ${CURKEY} \
                -t ${BINDIR}/task3/tasktext \
                -a ${halo} \
                -w ${shadow} \
                -q ${tec} \
                -V 1>> $LOG 2>&1

            if [ $? -ne 0 ];then
                return 3
            fi
        done
        echo -e "\n Technique complete...\n" >> $LOG

        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )

        echo -e "\n##### with Normal case #####" >> $LOG
        echo "##### under seeding resolution of ${fixres}x${fixres}x${fixres} #####" >> $LOG

        for((i=0;i<48;++i))
        do
            updatetaskprog

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi

            if [ ${cst} -eq 1 ];then
                CURFB="cst"
                CURKEY=1
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
                CURKEY=2
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
                CURKEY=3
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
                CURKEY=4
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG

            ${BINDIR}/task3/singleitr \
                -f \
                ${NORMALCASEDATADIR}/region_for_task3/s${fixres}/${CURFB}/pos1/region_s${fixres}.data \
                -s \
                ${NORMALCASEDATADIR}/region_for_task3/s${fixres}/${CURFB}/pos1/skeleton_region_s${fixres}.data \
                -i \
                ${NORMALCASEDATADIR}/region_for_task3/s${fixres}/${CURFB}/pos1/fiberidx_*_region_s${fixres}.data \
                -p ${TASKPROGIDFILE} \
                -r ${TUBERADIUS} \
                -k ${CURKEY} \
                -t ${BINDIR}/task3/tasktext \
                -a ${halo} \
                -w ${shadow} \
                -q ${tec} \
                -V 1>> $LOG 2>&1


            if [ $? -ne 0 ];then
                return 3
            fi
        done
        echo -e "\n Technique complete...\n" >> $LOG
    done
    return 0
}

#-----------------------------------------#
#
# task 4 
#
#-----------------------------------------#
function task4()
{
    taskflag 4

    local halo=0
    local shadow=0
    local cst=0
    local cc=0
    local ifo=0
    local ilf=0

    for NORMALCASEDATADIR in  ${ALLNORMALCASEDATADIRS}
    do
        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )


        echo -e "\n##### with Normal case #####" >> $LOG
        echo "##### under seeding resolution of ${fixres}x${fixres}x${fixres} #####" >> $LOG

        for((i=0;i<48;++i))
        do
            updatetaskprog

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi

            if [ ${cst} -eq 1 ];then
                CURFB="cst"
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG

            ${BINDIR}/task4/singleitr \
                -f \
                ${NORMALCASEDATADIR}/region_for_task4/s${fixres}/${CURFB}/region_s${fixres}.data \
                -s \
                ${NORMALCASEDATADIR}/region_for_task4/s${fixres}/${CURFB}/skeleton_region_s${fixres}.data \
                -j \
                ${NORMALCASEDATADIR}/region_for_task4/s${fixres}/${CURFB}/tumorbox_0_region_s${fixres}.data \
                -t ${BINDIR}/task4/tasktext \
                -p ${TASKPROGIDFILE} \
                -r ${TUBERADIUS} \
                -a ${halo} \
                -w ${shadow} \
                -q ${tec} \
                -V 1>> $LOG 2>&1

            if [ $? -ne 0 ];then
                    return 3
                fi
            done
            echo -e "\n Technique complete...\n" >> $LOG


        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )

        echo -e "\n##### with Normal case #####" >> $LOG
        echo "##### under seeding resolution of ${fixres}x${fixres}x${fixres} #####" >> $LOG

        # the same participant does the second block of task data
        for((i=0;i<48;++i))
        do

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi

            if [ ${cst} -eq 1 ];then
                CURFB="cst"
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG

                ${BINDIR}/task4/singleitr \
                    -f \
                    ${NORMALCASEDATADIR}/region_for_task4/s${fixres}/${CURFB}/pos1/region_s${fixres}.data \
                    -s \
                    ${NORMALCASEDATADIR}/region_for_task4/s${fixres}/${CURFB}/pos1/skeleton_region_s${fixres}.data \
                    -j \
                    ${NORMALCASEDATADIR}/region_for_task4/s${fixres}/${CURFB}/pos1/tumorbox_0_region_s${fixres}.data \
                    -t ${BINDIR}/task4/tasktext \
                    -p ${TASKPROGIDFILE} \
                    -r ${TUBERADIUS} \
                    -a ${halo} \
                    -w ${shadow} \
                    -q ${tec} \
                    -V 1>> $LOG 2>&1

                if [ $? -ne 0 ];then
                    return 3
                fi
            done
            echo -e "\n Technique complete...\n" >> $LOG
    done
    return 0
}

#-----------------------------------------#
#
# task 5 
#
#-----------------------------------------#
function task5()
{
    taskflag 5

    #local binchoices=(no yes yes no yes)
    local binchoices1=(yes no no no yes)
    local binchoices2=(yes yes no yes yes)
    local binchoices3=(no no no no yes)
    local binchoices4=(yes yes yes yes no)
    local binchoices5=(no no no no yes)
    local binchoices6=(yes yes no yes no)
    local binchoices7=(no no no yes yes)
    local binchoices8=(yes yes no no yes)
    local binchoices9=(yes no yes no yes)
    local binchoices10=(yes yes no yes yes)


    local halo=0
    local shadow=0
    local cst=0
    local cc=0
    local ifo=0
    local ilf=0
    local id=0


    for NORMALCASEDATADIR in  ${ALLNORMALCASEDATADIRS}
    do
        let "pidx = pi + 1"
        let "pidx2 = pidx + $NUMCOL"

        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )


        for((i=0;i<48;++i))
        do
            updatetaskprog

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi


            if [ ${cst} -eq 1 ];then
                CURFB="cst"
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi

            let "id=i % 4"
            CURCHOICE=$(eval echo \${binchoices${pidx}[$id]})


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo -e "\n##### with Normal case #####" >> $LOG
            echo "##### under seeding resolution of ${fixres}x${fixres}x${fixres} #####" >> $LOG
            echo "#####    when the answer is $CURCHOICE #### ">> $LOG
            FIBERIDXFILE="fiberidx_*_region_s${fixres}.data"
            if [ "$CURCHOICE" == "no" ];then
                FIBERIDXFILE="fiberidx_compound_region_s${fixres}.data"
            fi

            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG


            ${BINDIR}/task5/singleitr \
                -f \
                ${NORMALCASEDATADIR}/region_for_task5/s${fixres}/${CURFB}/region_s${fixres}.data \
                -s \
                ${NORMALCASEDATADIR}/region_for_task5/s${fixres}/${CURFB}/skeleton_region_s${fixres}.data \
                -i \
                ${NORMALCASEDATADIR}/region_for_task5/s${fixres}/${CURFB}/${CURCHOICE}/${FIBERIDXFILE} \
                -t ${BINDIR}/task5/tasktext \
                -p ${TASKPROGIDFILE} \
                -r ${TUBERADIUS} \
                -a ${halo} \
                -w ${shadow} \
                -q ${tec} \
                -V 1>> $LOG 2>&1

            if [ $? -ne 0 ];then
                return 3
            fi
        done
        echo -e "\n Technique complete...\n" >> $LOG


        # the same participant does the second block of task data
        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )


        for((i=0;i<48;++i))
        do
            updatetaskprog

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi


            if [ ${cst} -eq 1 ];then
                CURFB="cst"
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi

            let "id=i % 4"
            CURCHOICE=$(eval echo \${binchoices${pidx}[$id]})


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo -e "\n##### with Normal case #####" >> $LOG
            echo "##### under seeding resolution of ${fixres}x${fixres}x${fixres} #####" >> $LOG
            echo "#####    when the answer is $CURCHOICE #### ">> $LOG
            FIBERIDXFILE="fiberidx_*_region_s${fixres}.data"
            if [ "$CURCHOICE" == "no" ];then
                FIBERIDXFILE="fiberidx_compound_region_s${fixres}.data"
            fi

            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG


            ${BINDIR}/task5/singleitr \
                -f \
                ${NORMALCASEDATADIR}/region_for_task5/s${fixres}/${CURFB}/pos1/region_s${fixres}.data \
                -s \
                ${NORMALCASEDATADIR}/region_for_task5/s${fixres}/${CURFB}/pos1/skeleton_region_s${fixres}.data \
                -i \
                ${NORMALCASEDATADIR}/region_for_task5/s${fixres}/${CURFB}/pos1/${CURCHOICE}/${FIBERIDXFILE} \
                -t ${BINDIR}/task5/tasktext \
                -p ${TASKPROGIDFILE} \
                -r ${TUBERADIUS} \
                -a ${halo} \
                -w ${shadow} \
                -q ${tec} \
                -V 1>> $LOG 2>&1

            if [ $? -ne 0 ];then
                return 3
            fi
        done
        echo -e "\n Technique complete...\n" >> $LOG
    done
    return 0
}

#-----------------------------------------#
#
# task 6
#
#-----------------------------------------#
function task6()
{
    taskflag 6

    #local trichoices=(rightcut nocut leftcut nocut rightcut)
    local trichoices1=(rightcut rightcut nocut leftcut rightcut)
    local trichoices2=(leftcut rightcut nocut rightcut rightcut)
    local trichoices3=(leftcut rightcut leftcut rightcut nocut)
    local trichoices4=(nocut rightcut rightcut leftcut nocut)
    local trichoices5=(leftcut nocut rightcut nocut nocut)
    local trichoices6=(leftcut rightcut rightcut rightcut nocut)
    local trichoices7=(nocut nocut nocut leftcut leftcut)
    local trichoices8=(leftcut rightcut nocut nocut rightcut)
    local trichoices9=(nocut leftcut leftcut rightcut nocut)
    local trichoices10=(rightcut rightcut leftcut nocut rightcut)

    local halo=0
    local shadow=0
    local cst=0
    local cc=0
    local cg=0
    local ifo=0
    local ilf=0
    local id=0
    local n=${fixres}


    for NORMALCASEDATADIR in  ${ALLNORMALCASEDATADIRS}
    do
        let "pidx = pi + 1"
        let "pidx2 = pidx + $NUMCOL"

        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf phong_cg phong_halo_cg phong_des_cg phong_des_halo_cg tone_cg tone_halo_cg tone_des_cg tone_des_halo_cg hatching_cg hatching_halo_cg hatching_des_cg hatching_des_halo_cg" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )


        #FBARRARY=( $(echo "cst cg cc ifo ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )
        #echo "focus order:" ${FBARRARY[*]} >> $LOG

        for((i=0;i<48;++i))
        do
            updatetaskprog

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "cg=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_cg=( $( echo ${tec} | grep -o "_cg") )
            if [ "${if_cg}" == "_cg" ];then
                let "cg=1"
                tec=($(echo ${tec} | sed 's/_cg//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi


            if [ ${cst} -eq 1 ];then
                CURFB="cst"
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
            fi

            if [ ${cg} -eq 1 ];then
                CURFB="cg"
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi

            # change curfb according to task requirement
            if [ $CURFB = "cc" ];then
                CURFB="ilf"
            fi

            if [ $CURFB = "ifo" ];then
                CURFB="cst"
            fi


            let "id=i % 4"
            CURCHOICE=$(eval echo \${trichoices${pidx}[$id]})


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo -e "\n##### with Normal case #####" >> $LOG
            echo "##### under seeding resolution of ${n}x${n}x${n} #####" >> $LOG
            echo "#####    when the choice is $CURCHOICE #### ">> $LOG
            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG


            ${BINDIR}/task6/singleitr \
                -f \
                ${NORMALCASEDATADIR}/region_for_task6/s${n}/${CURFB}/region_s${n}.data \
                -i \
                ${NORMALCASEDATADIR}/region_for_task6/s${n}/${CURFB}/fiberidx_${CURCHOICE}_s${n}.data \
                -s \
                ${NORMALCASEDATADIR}/region_for_task6/s${n}/${CURFB}/skeleton_region_s${n}.data \
                -t ${BINDIR}/task6/tasktext \
                -p ${TASKPROGIDFILE} \
                -r ${TUBERADIUS} \
                -a ${halo} \
                -w ${shadow} \
                -q ${tec} \
                -V 1>> $LOG 2>&1

            if [ $? -ne 0 ];then
                return 3
            fi
        done
        echo -e "\n Technique complete...\n" >> $LOG


        # the same participant does the second block of task data

        TECHS=( $(echo "phong_cst phong_halo_cst phong_des_cst phong_des_halo_cst tone_cst tone_halo_cst tone_des_cst tone_des_halo_cst hatching_cst hatching_halo_cst hatching_des_cst hatching_des_halo_cst phong_cc phong_halo_cc phong_des_cc phong_des_halo_cc tone_cc tone_halo_cc tone_des_cc tone_des_halo_cc hatching_cc hatching_halo_cc hatching_des_cc hatching_des_halo_cc phong_ifo phong_halo_ifo phong_des_ifo phong_des_halo_ifo tone_ifo tone_halo_ifo tone_des_ifo tone_des_halo_ifo hatching_ifo hatching_halo_ifo hatching_des_ifo hatching_des_halo_ifo phong_ilf phong_halo_ilf phong_des_ilf phong_des_halo_ilf tone_ilf tone_halo_ilf tone_des_ilf tone_des_halo_ilf hatching_ilf hatching_halo_ilf hatching_des_ilf hatching_des_halo_ilf phong_cg phong_halo_cg phong_des_cg phong_des_halo_cg tone_cg tone_halo_cg tone_des_cg tone_des_halo_cg hatching_cg hatching_halo_cg hatching_des_cg hatching_des_halo_cg" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )


        #FBARRARY=( $(echo "cst cg cc ifo ilf" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )
        #echo "focus order:" ${FBARRARY[*]} >> $LOG

        for((i=0;i<48;++i))
        do
            updatetaskprog

            let "halo=0"
            let "shadow=0"
            let "cst=0"
            let "cc=0"
            let "cg=0"
            let "ifo=0"
            let "ilf=0"

            tec=${TECHS[$i]}

            echo "tech is:"${tec} >> $LOG

            # first get bundle name
            if_cst=( $( echo ${tec} | grep -o "_cst") )
            if [ "${if_cst}" == "_cst" ];then
                let "cst=1"
                tec=($(echo ${tec} | sed 's/_cst//g'))
            fi

            if_cc=( $( echo ${tec} | grep -o "_cc") )
            if [ "${if_cc}" == "_cc" ];then
                let "cc=1"
                tec=($(echo ${tec} | sed 's/_cc//g'))
            fi

            if_cg=( $( echo ${tec} | grep -o "_cg") )
            if [ "${if_cg}" == "_cg" ];then
                let "cg=1"
                tec=($(echo ${tec} | sed 's/_cg//g'))
            fi

            if_ifo=( $( echo ${tec} | grep -o "_ifo") )
            if [ "${if_ifo}" == "_ifo" ];then
                let "ifo=1"
                tec=($(echo ${tec} | sed 's/_ifo//g'))
            fi

            if_ilf=( $( echo ${tec} | grep -o "_ilf") )
            if [ "${if_ilf}" == "_ilf" ];then
                let "ilf=1"
                tec=($(echo ${tec} | sed 's/_ilf//g'))
            fi


            if [ ${cst} -eq 1 ];then
                CURFB="cst"
            fi

            if [ ${cc} -eq 1 ];then
                CURFB="cc"
            fi

            if [ ${cg} -eq 1 ];then
                CURFB="cg"
            fi

            if [ ${ifo} -eq 1 ];then
                CURFB="ifo"
            fi

            if [ ${ilf} -eq 1 ];then
                CURFB="ilf"
            fi

            flip=0
            if [ "$CURFB" == "cst" ];then
                flip=1
            fi

            # change curfb according to task requirement
            if [ $CURFB = "cc" ];then
                CURFB="ilf"
            fi

            if [ $CURFB = "ifo" ];then
                CURFB="cst"
            fi


            let "id=i % 4"
            CURCHOICE=$(eval echo \${trichoices${pidx2}[$id]})


            # get the technique
            if_halo=( $( echo ${tec} | grep -o "halo") )
            if [ "${if_halo}" == "halo" ];then
                let "halo=1"
                tec=($(echo ${tec} | sed 's/_halo//g'))
            fi

            if_shadow=( $( echo ${tec} | grep -o "des") )
            if [ "${if_shadow}" == "des" ];then
                let "shadow=1"
                tec=($(echo ${tec} | sed 's/_des//g'))
            fi

            echo -e "\n##### with Normal case #####" >> $LOG
            echo "##### under seeding resolution of ${n}x${n}x${n} #####" >> $LOG
            echo "#####    when the choice is $CURCHOICE #### ">> $LOG
            echo "curfb:"${CURFB}  "technique:" ${tec} "halo:"${halo} "shaow:"${shadow} >> $LOG


            ${BINDIR}/task6/singleitr \
                -f \
                ${NORMALCASEDATADIR}/region_for_task6/s${n}/${CURFB}/pos1/region_s${n}.data \
                -i \
                ${NORMALCASEDATADIR}/region_for_task6/s${n}/${CURFB}/pos1/fiberidx_${CURCHOICE}_s${n}.data \
                -s \
                ${NORMALCASEDATADIR}/region_for_task6/s${n}/${CURFB}/pos1/skeleton_region_s${n}.data \
                -t ${BINDIR}/task6/tasktext \
                -p ${TASKPROGIDFILE} \
                -r ${TUBERADIUS} \
                -a ${halo} \
                -w ${shadow} \
                -q ${tec} \
                -V 1>> $LOG 2>&1

            if [ $? -ne 0 ];then
                return 3
            fi
        done
        echo -e "\n Technique complete...\n" >> $LOG

    done
    return 0
}

function costOfThisTask()
{
    s=$1
    e=$2
    ((d=e-s))
    ((h=d/3600))
    ((m=d%3600/60))
    ((s=d%3600%60))
    echo " Time cost of this task: $h hours $m minutes $s seconds." >> $LOG
}

function execTasks()
{
    > $LOG

    bstart=`date +%s`

    for curtask in ${TASKDIRS}
    do 
        curstart=`date +%s`
        $curtask	
        ret=$?
        curend=`date +%s`
        costOfThisTask ${curstart} ${curend}

        if [ $ret -ne 0 ];then
            return 3
        fi
    done

    end=`date +%s`
    echo -e "\n################## ALL FINISHED #######################" >> $LOG
    ((d=end-bstart))
    ((h=d/3600))
    ((m=d%3600/60))
    ((s=d%3600%60))
    echo " Time cost: $h hours $m minutes $s seconds." >> $LOG
    return 0
}

#####################################################################################
###    Task ordering and main flow control
###
#####################################################################################

checkbins
if [ $? -ne 0 ];then
    exit 1
fi

checkdata
if [ $? -ne 0 ];then
    exit 1
fi

if [ $# -lt 1 ];then
    echo "Usage: $0 <participant index> [resolution]"
    exit 1
fi

pi=$1

fixres=3
if [ $# -ge 3 ];then
    fixres=$3
fi

LOG="${LOG}_p${pi}_mono"
let "pi -= 1"

NUMCOL=1
CURORDER="1 2"

execTasks
ret=$?

rm -rf ${TASKPROGIDFILE}

if [ $ret -eq 0 ];then
    echo "All finished, thank you!"
else
    echo "Study terminated in advance, thank you all the same."
fi
echo

exit 0

