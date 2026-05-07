echo "Creando Grupo de Solicitudes definido en $1"
FNDLOAD $CONNECT_STRING O Y UPLOAD $FND_TOP/patch/115/import/afcpreqg.lct $1 - CUSTOM_MODE=FORCE UPLOAD_MODE=REPLACE   
       
