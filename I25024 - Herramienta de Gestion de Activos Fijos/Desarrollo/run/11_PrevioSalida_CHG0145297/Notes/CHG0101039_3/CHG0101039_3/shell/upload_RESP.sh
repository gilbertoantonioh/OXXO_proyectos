echo "Creando Responsabilidad definido en $1"
FNDLOAD $CONNECT_STRING O Y UPLOAD $FND_TOP/patch/115/import/afscursp.lct  $1 - CUSTOM_MODE=FORCE UPLOAD_MODE=REPLACE 