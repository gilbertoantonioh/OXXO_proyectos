echo "Creando Menu definido en $1"
FNDLOAD $CONNECT_STRING 0 Y UPLOAD $FND_TOP/patch/115/import/afsload.lct $1 MENU - CUSTOM_MODE=FORCE UPLOAD_MODE=REPLACE        
