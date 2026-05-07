VARPWD=`pwd`

for filename in `ls -1 $VARPWD/*.log`
do
   echo "  "
   echo "  "
   echo "=================================================================="
   echo "=====" $filename
   echo "=================================================================="
   echo "  "
   echo "  "
   while read line
   do
      echo " " $line
   done<$filename
done
