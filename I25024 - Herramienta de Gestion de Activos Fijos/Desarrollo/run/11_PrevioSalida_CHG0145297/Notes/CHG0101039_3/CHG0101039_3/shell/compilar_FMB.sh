CURR_PWD=$(pwd)
cd application/forms
cp $1.fmb $AU_TOP/forms/US
cd $AU_TOP/forms/US
frmcmp_batch module=$1.fmb userid=$CONNECT_STRING module_type=FORM
cp $1.fmx $2/forms/US/
cp $1.fmx $2/forms/ESA/
cd $CURR_PWD
