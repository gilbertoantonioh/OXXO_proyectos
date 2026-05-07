echo "Creando Perfil definido en $1"
FNDLOAD $CONNECT_STRING 0 Y UPLOAD $FND_TOP/patch/115/import/afscprof.lct $1 - CUSTOM_MODE=FORCE UPLOAD_MODE=REPLACE
