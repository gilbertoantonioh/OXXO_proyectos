echo "Creando objeto XML Publisher definido en $1"
FNDLOAD $CONNECT_STRING 0 Y UPLOAD $XDO_TOP/patch/115/import/xdotmpl.lct $1 - CUSTOM_MODE=FORCE UPLOAD_MODE=REPLACE          
