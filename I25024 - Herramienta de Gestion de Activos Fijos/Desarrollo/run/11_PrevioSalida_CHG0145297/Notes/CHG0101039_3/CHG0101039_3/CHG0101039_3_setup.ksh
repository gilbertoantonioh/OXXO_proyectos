# SECCION INICIAL DEL SCRIPT DE INSTALACION # 
# CAPTURAR LOS DATOS REQUERIDOS # 

VARPWD=$(pwd)

# Valores para el parametro INSTANCIA
# "MEXICO"
# "COLOMBIA"
# "IMMEX"

#INSTANCIA="MEXICO"
#export INSTANCIA

. /u01/ebs_fs/$INSTANCIA/INSTALL_CONFIG.ENV

CHANGE_ORDER="CHG0101039"
export CHANGE_ORDER

CORREO="martin.verdeja@serviciosexternos.com.mx,juanp.carrera@oxxo.com"

export=CORREO

CO_LOGFILE=$VARPWD/CHG0101039_3_LOG.log
export CO_LOGFILE

#. SHELL/valida_instancia.ksh $INSTANCIA $CHANGE_ORDER $CORREO > $CO_LOGFILE
#-----------------------------------------------------------------------------------------------------------
# TERMINA SECCION INICIAL DEL SCRIPT DE INSTALACION #
# N O   B O R R A R #
#-----------------------------------------------------------------------------------------------------------
echo "Inicia la instalacion: $(date)" >> $CO_LOGFILE
echo " " >> $CO_LOGFILE
echo " Ajuste de precio de los Activos (costo de compra) " >> $CO_LOGFILE 
echo " " >> $CO_LOGFILE
#--   Se cambia al directorio base del CHO    --------------------------------------------------------------
cd $VARPWD
#-----------------------------------------------------------------------------------------------------------
echo " " >> $CO_LOGFILE

#-----------------------------------------------------------------------------------------------------------
echo " " >> $CO_LOGFILE

cd $VARPWD


#-----------------------------------------------------------------------------------------------------------


echo "========> Generacion de concurrentes Proyecto - Ajuste de precio de los Activos (costo de compra)  <========" >> $CO_LOGFILE


#-----------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------
echo " " >> $CO_LOGFILE
echo "========> Se ejecuta script en BD de APPS <========"  >> $CO_LOGFILE
sqlplus -s /nolog << EOF
connect $CONNECT_STRING
spool checkerr.out
clear buffer

PROMPT ------> Ejecutando depurado de info de tabla XXINV_MATERIAL_TRX_TEMP
@database/sqls/APPS_XXINV_MATERIAL_TRX_TEMP_DELETE.sql
show err

spool off
exit;
EOF
cat checkerr.out >> $CO_LOGFILE

#-----------------------------------------------------------------------------------------------------------
echo "========> Se crean objetos de BDs en XXFC <========"  >> $CO_LOGFILE
sqlplus -s /nolog << EOF
connect $CONNECT_STRING_XXFC
spool checkerr.out
clear buffer

prompt ### Instalando objetos en XXFC ###


PROMPT ------> Borrando la tabla XXINV_CTRL_FA_MASS_ADDITIONS
@database/tables/XXFC_XXINV_CTRL_FA_MASS_ADDITIONS_TBL.sql
show err

PROMPT ------> Creando la tabla XXFC_SN_ESCANEO
@database/tables/XXFC_XXFC_SN_ESCANEO_TBL.sql
show err

PROMPT ------> Creando la tabla XXFC_SN_ESCANEO_LINEAS
@database/tables/XXFC_XXFC_SN_ESCANEO_LINEAS_TBL.sql
show err

PROMPT ------> Creando la tabla XINV_PRE_MATERIAL_TRX_TEMP
@database/tables/XXFC_XXINV_PRE_MATERIAL_TRX_TEMP_TBL.sql
show err

PROMPT ------> Agregando campos a la tabla XXINV_MATERIAL_TRX_TEMP
@database/alters/XXFC_XXINV_MATERIAL_TRX_TEMP_ALTER.sql
show err

PROMPT ------> Agregando campos a la tabla XXINV_MATERIAL_TRANSACTIONS
@database/alters/XXFC_XXINV_MATERIAL_TRANSACTIONS_ALTER.sql
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

PROMPT ------> Depurando registro a mapeos varios
@database/sqls/delete_xxfc_mapeos_varios_XXFC_INV_ADMON_ACTIVOS.sql
show err

PROMPT ------> Creando secuencia XXINV_REF_LINES_S
@database/sequences/XXFC_XXINV_REF_LINES_SEQ.sql
show err

PROMPT ------> Creando secuencia SN_ESCANEO_ID_SEQ
@database/sequences/XXFC_SN_ESCANEO_ID_SEQ.sql
show err

PROMPT ------> Actualizando objetos de XXFC_SN_ESCANEO
@database/tables/APPS_XXFC_SN_ESCANEO_ADOP.sql
show err

PROMPT ------> Actualizando objetos de SN_ESCANEO_LINEAS
@database/tables/APPS_XXFC_SN_ESCANEO_LINEAS_ADOP.sql
show err

PROMPT ------> Actualizando objetos de XXINV_MATERIAL_TRX_TEMP
@database/tables/APPS_XXINV_MATERIAL_TRX_TEMP_ADOP.sql
show err

PROMPT ------> Actualizando objetos de XXINV_PRE_MATERIAL_TRX_TEMP
@database/tables/APPS_XXINV_PRE_MATERIAL_TRX_TEMP_ADOP.sql
show err

PROMPT ------> Actualizando objetos de XXINV_MATERIAL_TRANSACTIONS
@database/tables/APPS_XXINV_MATERIAL_TRANSACTIONS_ADOP.sql
show err

PROMPT ------> Compilacion especificacion del paquete XXINV_ITEM_FIXED_ASSET_WEB_PKG
@database/plsqls/APPS_XXINV_ITEM_FIXED_ASSET_WEB_PKG_PKS.sql
show err

PROMPT ------> Compilacion body del paquete XXINV_ITEM_FIXED_ASSET_WEB_PKG
@database/plsqls/APPS_XXINV_ITEM_FIXED_ASSET_WEB_PKG_PKB.sql
show err

PROMPT ------> Compilacion especificacion del paquete APPS_XXINV_KITS_CUENTAS_DIARIO_PKS
@database/plsqls/APPS_XXINV_KITS_CUENTAS_DIARIO_PKS.sql
show err

PROMPT ------> Compilacion body del paquete APPS_XXINV_KITS_CUENTAS_DIARIO_PKB
@database/plsqls/APPS_XXINV_KITS_CUENTAS_DIARIO_PKB.sql
show err

spool off
exit;
EOF
cat checkerr.out >> $CO_LOGFILE


cd $VARPWD

#
#------------------------------------------ FIN DE INSTALACION ----------------------------------------------
#
echo " " >> $CO_LOGFILE
echo "Fin de la instalacion: $(date)" >> $CO_LOGFILE
cd $VARPWD
#. SHELL/archivos_log.ksh >> $CO_LOGFILE

mailx -s "Instalacion Automatica del Change Order $CHANGE_ORDER" $CORREO < $CO_LOGFILE
