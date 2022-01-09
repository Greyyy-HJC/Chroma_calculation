#!/bin/bash

#SBATCH --job-name=3pt
#SBATCH --partition=cpu
#SBATCH --mail-type=end
#SBATCH --mail-user=hejinchen17@mails.ucas.ac.cn
#SBATCH --output=test.sh.out
#SBATCH --error=test.sh.err
#SBATCH --array=0
#SBATCH -N 8
#SBATCH --exclude="cas361, cas356"
#SBATCH --time=00:60:00
#SBATCH --ntasks-per-node=32
#SBATCH --exclusive

export OMP_NUM_THREADS=1


nsrc=2 #source 数量
it0=32 #第一个source 所处it0位置


jobs=jobs_demo_${nsrc}${it0}
directer=Data_demo_${nsrc}${it0}
Dini_out=ini_outfile_demo_${nsrc}${it0}
Dlog=logfile_demo_${nsrc}${it0}
txt=txt_demo_${nsrc}${it0}

#创建上述文件夹
if [ ! -d "./${directer}/" ]; then
	mkdir ${directer}
else
	echo file exist
fi

if [ ! -d "./${Dini_out}/" ]; then
	mkdir ${Dini_out}
else
	echo file exist
fi

if [ ! -d "./${Dlog}/" ]; then
	mkdir ${Dlog}
else
	echo file exist
fi

if [ ! -d "./${txt}/" ]; then
	mkdir ${txt}
else
	echo file exist
fi


rm -rf "./${jobs}/"
var=$(cat list_p) #读取list列表中的组态号，需当前目录有list的txt文档存组态号

for i in ${var[*]} #循环list中的所有组态号
do 
	grep -q  'CHROMA: ran successfully' ./${Dlog}/log.${i}.${it0} #grep logfile是否i组态已经计算过，如果计算过“i”组态跳过 #grep -p 匹配到内容则返回“0”
	if [ $? -eq "0"  ]; then  #上次返回为“0”则无操作，继续循环
		continue
	else
		mkdir -p "./${jobs}/${i}_${it0}" #在job文件夹中创建job文件夹，以组态编号命名，后续将读取文件名获取组态编号提交任务
	fi
done


while true #此处死循环是为了服务器节点问题导致某个组态计算失败时重新提交
do
	count=`ls ./${jobs}|wc -w`
	if [ $count -eq "0"  ]; then
		break
	fi
	xx=`ls -r ./${jobs} | tail -1` #ls job文件夹中文件名，获取组态编号及it0
	it=${xx##*_} #获取it0
	i=${xx%%_*} #获取组态编号
        rm -rf "./${jobs}/${i}_${it}" #提交组态编号i，it0为it的任务，同时删除job文件夹中对应命名的文件夹       
	./cls_3pt_demo.pl  ${i} ./${directer}/ ${nsrc} ${it0}   >./${Dini_out}/ini.${i}.${it} 
	#运行pl脚本，给pl脚本参数为组态“i”, 夸克mass“ini_mass”, 输出路径${directer}， source数量${n_src}， it0，，，，>箭头后为pl脚本打印xml文档位置

    srun  -n 256 ./chroma  -i ./${Dini_out}/ini.${i}.${it}  -o ./${Dini_out}/out.${i}.${it}   >./${Dlog}/log.${i}.${it}   2>&1
	#运行chroma， -i chroma读取ini参数， -o chroma检查的out参数， geom gpu分配线程，与mglayout相关， >chroma运行输出日志

	grep -q  'CHROMA: ran successfully' ./${Dlog}/log.${i}.${it}
#
	# if [ $? -eq "1"  ]; then
    #            mkdir -p "./${jobs}/${i}_${it}"
	# fi 

    break #计算完当前任务无论是否成功break，测试用，产生数据请注掉break
done


