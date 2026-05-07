#! /bin/ksh
#------------------------------------------------------------------------------------------------------------------
#  File:   XXFA_EBS_SN_OUT_BIN.ksh                           v.1
#  Author: Fabiola Sanchez
#
#  Desc: Ejecuta el concurrente XXFA - SN Generacion de Archivos de Integracion
#------------------------------------------------------------------------------------------------------------------
# Modification History                                                
# =================================================================================================================                                                 
# Who              Date             Description                             
# -------------    -------------    ------------------------------------                            
# Fabiola Sanchez  19/09/2025       CHG0113891 Ejecuta el concurrente XXFA - SN Generacion de Archivos de Integracion
#                                    
#------------------------------------------------------------------------------------------------------------------

echo "==============> Inicia Proceso: $(date) <==============" 
echo "==============> XXFA - SN Generacion de Archivos de Integracion <=============" 
. /u01/ebs_fs/$INSTANCIA/INSTALL_CONFIG.ENV
$ORACLE_HOME/bin/sqlplus -s /nolog << EOF
connect $CONNECT_STRING

set serveroutput on size 20000;

DECLARE
  lv_errbuf     VARCHAR2 (4000);
  lv_retcode    VARCHAR2 (1);
  lv_tipo_mapeo VARCHAR2 (1000):='XXFA_EBS_SN_FILE_OUT';
BEGIN

  XXFA_EBS_SN_UTIL_PKG.ejecuta_concurrente_prc(lv_errbuf,lv_retcode,lv_tipo_mapeo);

EXCEPTION 
   WHEN OTHERS THEN
      lv_errbuf  :='Ocurrio un error el proceso XXFA_EBS_SN_UTIL_PKG.ejecuta_concurrente_prc ['||lv_tipo_mapeo||']';
      dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||lv_errbuf);         
END;
/
EOF
echo "==============> Termina Proceso: $(date) <=============="