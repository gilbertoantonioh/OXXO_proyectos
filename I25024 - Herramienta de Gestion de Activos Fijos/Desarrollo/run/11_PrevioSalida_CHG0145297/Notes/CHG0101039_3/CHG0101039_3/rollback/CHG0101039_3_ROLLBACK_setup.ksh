# SECCION INICIAL DEL SCRIPT DE INSTALACION #
# CAPTURAR LOS DATOS REQUERIDOS #

VARPWD=$(pwd)

# Valores para el parametro INSTANCIA
# "MEXICO"
# "COLOMBIA"
# "IMMEX"

# INSTANCIA="MEXICO"
# export INSTANCIA

. /u01/ebs_fs/$INSTANCIA/INSTALL_CONFIG.ENV

CHANGE_ORDER="CHG0101039"
export CHANGE_ORDER
 
CORREO="martin.verdeja@serviciosexternos.com.mx,juanp.carrera@oxxo.com"
export CORREO

CO_LOGFILE=$VARPWD/CHG0101039_3_RB.txt
export CO_LOGFILE

# . SHELL/valida_instancia.ksh $INSTANCIA $CHANGE_ORDER $CORREO > $CO_LOGFILE  ### NOTA: Ya no se aplica para 12.2.4
#-----------------------------------------------------------------------------------------------------------
# TERMINA SECCION INICIAL DEL SCRIPT DE INSTALACION #
# N O   B O R R A R #
#-----------------------------------------------------------------------------------------------------------
echo "Inicia la instalacion: $(date)" >> $CO_LOGFILE
echo " " >> $CO_LOGFILE

#--   Se cambia al directorio base del CHO    --------------------------------------------------------------
cd $VARPWD
#
# Aqui hay que agregar los scripts SQL de los objetos de base de datos, sin extension
#
#--   Se cambia al directorio base del CHO    --------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------

echo "========> Generacion de concurrentes Proyecto - Ajuste de precio de los Activos (costo de compra)  <========" >> $CO_LOGFILE

#-----------------------------------------------------------------------------------------------------------
echo "========> Se crean objetos de BDs en XXFC <========"  >> $CO_LOGFILE
sqlplus -s /nolog << EOF
connect $CONNECT_STRING_XXFC
spool checkerr.out
clear buffer

prompt ### Instalando objetos en XXFC ###

PROMPT ------> Eliminando campos de la tabla XXINV_MATERIAL_TRX_TEMP
@database/alters/XXFC_XXINV_MATERIAL_TRX_TMP_DROP.sql
show err

PROMPT ------> Eliminando campos de la tabla XXINV_MATERIAL_TRANSACTIONS
@database/alters/XXFC_XXINV_MATERIAL_TRANSACTIONS_DROP.sql
show err

spool off
exit;
EOF
cat checkerr.out >> $CO_LOGFILE


#-----------------------------------------------------------------------------------------------------------


echo " " >> $CO_LOGFILE
echo "========> Se crean objetos de BDs en APPS <========"  >> $CO_LOGFILE
sqlplus -s /nolog << EOF
connect $CONNECT_STRING
spool checkerr.out
clear buffer

PROMPT ------> Eliminando la secuencia XXINV_REF_LINES_S
@database/sequences/XXINV_REF_LINES_S_DROP.sql
show err

PROMPT ------> Eliminando la secuencia SN_ESCANEO_ID_SEQ
@database/sequences/SN_ESCANEO_ID_SEQ_DROP.sql
show err

PROMPT ------> Eliminando la tabla XXFC_SN_ESCANEO_LINEAS
@database/tables/APPS_XXFC_SN_ESCANEO_LINEAS_DROP.sql
show err

PROMPT ------> Eliminando la tabla XXFC_SN_ESCANEO
@database/tables/APPS_XXFC_SN_ESCANEO_DROP.sql
show err

PROMPT ------> Eliminando la tabla XXINV_PRE_MATERIAL_TRX_TEMP
@database/tables/APPS_XXINV_PRE_MATERIAL_TRX_TEMP_DROP.sql
show err

PROMPT ------> Actualizando objetos de XXINV_MATERIAL_TRX_TEMP
@database/tables/APPS_XXINV_MATERIAL_TRX_TEMP_ADOP.sql
show err

PROMPT ------> Actualizando objetos de XXINV_MATERIAL_TRANSACTIONS
@database/tables/APPS_XXINV_MATERIAL_TRANSACTIONS_ADOP.sql
show err



PROMPT ------> Compilacion ESPECIFICACION paquete version anterior APPS_XXINV_ITEM_FIXED_ASSET_WEB_PKG_PKS
@database/plsqls/APPS_XXINV_ITEM_FIXED_ASSET_WEB_PKG_PKS.sql
show err

PROMPT ------> Compilacion BODY paquete version anterior APPS_XXINV_ITEM_FIXED_ASSET_WEB_PKG_PKB
@database/plsqls/APPS_XXINV_ITEM_FIXED_ASSET_WEB_PKG_PKB.sql
show err

PROMPT ------> Compilacion ESPECIFICACION paquete version anterior APPS_XXINV_KITS_CUENTAS_DIARIO_PKS
@database/plsqls/APPS_XXINV_KITS_CUENTAS_DIARIO_PKS.sql
show err

PROMPT ------> Compilacion BODY paquete version anterior APPS_XXINV_KITS_CUENTAS_DIARIO_PKB
@database/plsqls/APPS_XXINV_KITS_CUENTAS_DIARIO_PKB.sql
show err

spool off
exit;
EOF
cat checkerr.out >> $CO_LOGFILE
 
#
#-----------------------------------------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------------------------------------
# SECCION FINAL DEL SCRIPT DE INSTALACION #
# N O   B O R R A R #
#-----------------------------------------------------------------------------------------------------------
#
#------------------------------------------ FIN DE INSTALACION ---------------------------------------------
#
echo " " >> $CO_LOGFILE
echo "Fin de la instalacion: $(date)" >> $CO_LOGFILE
cd $VARPWD
#. SHELL/archivos_log.ksh >> $CO_LOGFILE
mailx -s "Rollback Automatico del Change Order $CHANGE_ORDER" $CORREO < $CO_LOGFILE
#
