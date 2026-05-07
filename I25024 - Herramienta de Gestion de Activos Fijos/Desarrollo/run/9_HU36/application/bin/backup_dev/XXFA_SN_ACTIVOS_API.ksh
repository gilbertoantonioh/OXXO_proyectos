#! /bin/ksh
#------------------------------------------------------------------------------------------------------------------
#  File:   XXFA_SN_ACTIVOS_API.ksh  v.1
#  Author: Samanta Solis
#
#  Desc: Ejecuta el concurrente XXFA - SN_DATA_DETAILS Actualiza Activos
#------------------------------------------------------------------------------------------------------------------
# Modification History                                                
# =================================================================================================================                                                 
# Who              Date             Description                             
# -------------    -------------    ------------------------------------                            
# Samanta Solis    09/10/2025       CHG0116809 Ejecuta el concurrente XXFA - SN_DATA_DETAILS Actualiza Activos
# Fabiola Sanchez  12/01/2026       CHG0137341 Ajuste para ejecutar varios concurrentes usando un mapeo
#------------------------------------------------------------------------------------------------------------------

echo "==============> Inicia Proceso: $(date) <==============" 
echo "==============> XXFA_SN_ACTIVOS_API <=============" 
. /u01/ebs_fs/$INSTANCIA/INSTALL_CONFIG.ENV
$ORACLE_HOME/bin/sqlplus -s /nolog << EOF
connect $CONNECT_STRING

set serveroutput on size 20000;

DECLARE
  lv_errbuf      VARCHAR2 (4000);
  lv_retcode     VARCHAR2 (1);
  
  CURSOR cur_Mapeos 
   IS
      SELECT entrada tipo_mapeo
      FROM   xxfc_mapeos_varios
      WHERE  tipo_mapeo = 'XXFA_EBS_SN_DIARIO'
      AND    estado = 'A'; 
BEGIN
   FOR c IN cur_Mapeos
   LOOP
      BEGIN
         XXFA_EBS_SN_UTIL_PKG.ejecuta_concurrente_prc(lv_errbuf,lv_retcode,c.tipo_mapeo);
         
      EXCEPTION 
         WHEN OTHERS THEN
            lv_errbuf  :='Ocurrio un error el proceso XXFA_EBS_SN_UTIL_PKG.ejecuta_concurrente_prc ['||c.tipo_mapeo||']';
            dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||lv_errbuf);         
      END;
   END LOOP;
   
END;
/
EOF
echo "==============> Termina Proceso: $(date) <=============="