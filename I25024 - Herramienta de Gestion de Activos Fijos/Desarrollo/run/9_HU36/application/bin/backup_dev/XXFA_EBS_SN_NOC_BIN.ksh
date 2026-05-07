#! /bin/ksh
#------------------------------------------------------------------------------------------------------------------
#  File:   XXFA_EBS_REC_INVOICE_BIN.ksh  v.1
#  Author: Fabiola Sanchez
#
#  Desc: Ejecuta el concurrentes 
#------------------------------------------------------------------------------------------------------------------
# Modification History                                                
# =================================================================================================================                                                 
# Who              Date             Description                             
# -------------    -------------    ------------------------------------                            
# Fabiola Sanchez  27/02/2026       CHG0140507 Ejecuta concurrentes
#------------------------------------------------------------------------------------------------------------------

echo "==============> Inicia Proceso: $(date) <==============" 
echo "==============> XXFA_EBS_REC_INVOICE_BIN <=============" 
. /u01/ebs_fs/$INSTANCIA/INSTALL_CONFIG.ENV
$ORACLE_HOME/bin/sqlplus -s /nolog << EOF
connect $CONNECT_STRING

set serveroutput on size 20000;

DECLARE
  lv_errbuf      VARCHAR2 (4000);
  lv_retcode     VARCHAR2 (1);
  
  lv_param1 xxfc_mapeos_varios.salida1%TYPE := NULL;
  lv_param2 xxfc_mapeos_varios.salida2%TYPE := NULL;
  lv_param3 xxfc_mapeos_varios.salida3%TYPE := NULL;
  lv_param4 xxfc_mapeos_varios.salida4%TYPE := NULL;
  lv_param5 xxfc_mapeos_varios.salida5%TYPE := NULL;
  lv_param6 xxfc_mapeos_varios.salida6%TYPE := NULL;
  lv_param7 xxfc_mapeos_varios.salida7%TYPE := NULL;
  lv_param8 xxfc_mapeos_varios.salida8%TYPE := NULL;
  lv_param9 xxfc_mapeos_varios.salida9%TYPE := NULL;
  lv_param10 xxfc_mapeos_varios.salida10%TYPE  := NULL;
  
  eParametros  EXCEPTION;
  
  CURSOR cur_Mapeos 
   IS
      SELECT entrada tipo_mapeo, salida1 parametros
      FROM   xxfc_mapeos_varios
      WHERE  tipo_mapeo = 'XXFA_EBS_SN_NOCTURNO'
      AND    estado = 'A'; 
   
   FUNCTION valida_parametro_fnc(pv_param  IN VARCHAR2)
   RETURN VARCHAR2
   IS
      ld_fecha    DATE;
      ln_number   NUMBER;
      lv_text     VARCHAR2(250);
      
      BEGIN
         IF pv_param IS NULL
         THEN
            RETURN CHR(0);
         END IF;
         
         EXECUTE IMMEDIATE 'SELECT '||pv_param ||' FROM DUAL' INTO ld_fecha;
         RETURN FND_DATE.DATE_TO_CANONICAL(ld_fecha);
         
         EXCEPTION
         WHEN OTHERS
         THEN
            BEGIN
               EXECUTE IMMEDIATE  'SELECT '||pv_param ||' FROM DUAL' INTO ln_number;
               RETURN TO_CHAR(ln_number);
            EXCEPTION
               WHEN OTHERS
               THEN
                  BEGIN
                     EXECUTE IMMEDIATE  'SELECT '||pv_param ||' FROM DUAL' INTO lv_text;
                     RETURN lv_text;
                  EXCEPTION   
                     WHEN OTHERS
                     THEN
                        RETURN pv_param;
                  END;   
            END;
   END  valida_parametro_fnc;
BEGIN
   FOR c IN cur_Mapeos
   LOOP
      IF c.parametros = 'S'
      THEN 
         --Busca parametros
         BEGIN
            SELECT salida1,salida2,salida3,salida4,salida5,salida6,salida7,salida8,salida9,salida10
            INTO   lv_param1, lv_param2, lv_param3,lv_param4,lv_param5,lv_param6,lv_param7,lv_param8,lv_param9,lv_param10
            FROM   xxfc_mapeos_varios
            WHERE  tipo_mapeo = 'XXFA_EBS_SN_NOC_PARAM'
            AND    entrada    = c.tipo_mapeo;
         EXCEPTION   
            WHEN OTHERS
            THEN  
               lv_errbuf := 'Error al obtener los parametros para: '||c.tipo_mapeo|| ' '||SQLERRM;
               dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||lv_errbuf); 
               CONTINUE;
               --RAISE eParametros;
         END ; 
      END IF;      

      BEGIN
         XXFA_EBS_SN_UTIL_PKG.ejecuta_concurrente_prc(xv_errbuf => lv_errbuf
                                                     ,xv_retcode => lv_retcode
                                                     ,pv_tipo_mapeo => c.tipo_mapeo
                                                     ,pv_argument1 => valida_parametro_fnc(lv_param1)
                                                     ,pv_argument2 => valida_parametro_fnc(lv_param2)
                                                     ,pv_argument3 => valida_parametro_fnc(lv_param3)
                                                     ,pv_argument4 => valida_parametro_fnc(lv_param4)
                                                     ,pv_argument5 => valida_parametro_fnc(lv_param5)
                                                     ,pv_argument6 => valida_parametro_fnc(lv_param6)
                                                     ,pv_argument7 => valida_parametro_fnc(lv_param7)
                                                     ,pv_argument8 => valida_parametro_fnc(lv_param8)
                                                     ,pv_argument9 => valida_parametro_fnc(lv_param9)
                                                     ,pv_argument10 => valida_parametro_fnc(lv_param10)
                                                     );
         
      EXCEPTION 
         WHEN OTHERS 
         THEN
            lv_errbuf  :='Ocurrio un error en proceso XXFA_EBS_SN_UTIL_PKG.ejecuta_concurrente_prc ['||c.tipo_mapeo||']'|| ' '||SQLERRM;
            dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||lv_errbuf);         
      END;
   END LOOP;
   
END;
/
EOF
echo "==============> Termina Proceso: $(date) <=============="