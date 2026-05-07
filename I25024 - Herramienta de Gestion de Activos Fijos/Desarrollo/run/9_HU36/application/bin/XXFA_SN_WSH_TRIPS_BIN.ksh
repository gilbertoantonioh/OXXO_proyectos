#! /bin/ksh
#------------------------------------------------------------------------------------------------------------------
#  File:   XXFA_SN_WSH_TRIPS_BIN.ksh                           v.1
#  Author: Gilberto Hernandez
#
#  Desc: Ejecuta el concurrente XXFA - SN Actualiza Informacion de Viajes WSH
#------------------------------------------------------------------------------------------------------------------
# Modification History                                                
# =================================================================================================================                                                 
# Who              Date             Description                             
# -------------    -------------    ------------------------------------                            
# Gilberto Hernandez (Hexaware)   4/Mar/2026       CHG0143308      Programar el registro de los viajes que se comparten con service now
#                                    
#------------------------------------------------------------------------------------------------------------------

echo "==============> Inicia Proceso: $(date) <==============" 
echo "==============> XXFA - SN Actualiza Informacion de Viajes WSH <=============" 
. /u01/ebs_fs/$INSTANCIA/INSTALL_CONFIG.ENV
$ORACLE_HOME/bin/sqlplus -s /nolog << EOF
connect $CONNECT_STRING

set serveroutput on size 20000;

DECLARE
  lv_errbuf     VARCHAR2 (4000);
  lv_retcode    VARCHAR2 (1);
  lv_tipo_mapeo VARCHAR2 (1000):='XXFA_SN_WSH_TRIPS_BIN';
BEGIN

  XXFA_EBS_SN_UTIL_PKG.ejecuta_concurrente_prc(lv_errbuf,lv_retcode,lv_tipo_mapeo, NULL, NULL);

EXCEPTION 
   WHEN OTHERS THEN
      lv_errbuf  :='Ocurrio un error el proceso XXFA_EBS_SN_UTIL_PKG.ejecuta_concurrente_prc ['||lv_tipo_mapeo||']';
      dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||lv_errbuf);         
END;
/
EOF
echo "==============> Termina Proceso: $(date) <=============="