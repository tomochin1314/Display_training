#!bin/bash

CURORDER="1 2 3"
for i in ${CURORDER}
do
    echo ${i}
done

HALO="halo"
TECH="phong_des_halo"
#tec = ( $(grep -o halo ${TECH}))
tec=( $( echo ${TECH} | grep -o "halo") )
if [ "${tec}" == "halo" ];then
    echo ${tec}
    tec=( $( echo ${TECH} | sed 's/_halo//g'  ) )
    echo ${tec} 
fi
    
