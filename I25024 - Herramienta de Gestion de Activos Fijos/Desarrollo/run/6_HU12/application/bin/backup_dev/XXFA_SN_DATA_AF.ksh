#! /bin/ksh
#------------------------------------------------------------------------------------------------------------------
#  File:   XXFA_SN_DATA_AF.ksh                                                                                  v.1
#  Author: Samanta Solis
#
#  Desc: Ejecuta el concurrente XXFA - SN Generacion de Datos Atributos Activo Fijo
#------------------------------------------------------------------------------------------------------------------
# Modification History                                                
# =================================================================================================================
# Who              Date             Description                             
# -------------    -------------    -------------------------------------------------------------------------------
# Samanta Solis    23/12/2025       CHG0135817 Ejecuta el concurrente
#                                    
#------------------------------------------------------------------------------------------------------------------

echo "==============> Inicia Proceso: $(date) <==============" 
echo "==============> XXFA_SN_DATA_AF <=============" 
. /u01/ebs_fs/$INSTANCIA/INSTALL_CONFIG.ENV
$ORACLE_HOME/bin/sqlplus -s /nolog << EOF
connect $CONNECT_STRING
set serveroutput on size 20000;

DECLARE
   lv_errbuf       VARCHAR2(4000);
   ln_retcode      NUMBER;
   lv_cia          VARCHAR2(250);
   lv_plazas       VARCHAR2(250);
   lv_lista_crs    VARCHAR2(250);
   lv_distrito_id  VARCHAR2(250);
   lv_giro_ef      VARCHAR2(250);
   lv_categoria    VARCHAR2(250);
   lv_sub_cat      VARCHAR2(250);
   lv_familia      VARCHAR2(250);
   lv_clave_activo VARCHAR2(250);
   lv_tipo_activo  VARCHAR2(250);
   lv_periodo      VARCHAR2(250);
   lv_libro        VARCHAR2(250);
   lv_divisor      VARCHAR2(250);
   ln_divisor      NUMBER;
   lv_mostrarME    VARCHAR2(250);
   lv_mapeo        VARCHAR2(250):= 'XXFA_SN_DATA_AF_PARAMETROS';
   lv_origen       VARCHAR2(250):= 'AUTOMATICO';
   lv_tipo_mapeo VARCHAR2(4000) := 'XXFA_SN_DATA_AF';
   
   ltyp_mapeo xxfc_mapeos_varios%ROWTYPE;
   CURSOR cur_Mapeos
   IS
      SELECT *
      FROM   xxfc_mapeos_varios
      WHERE  tipo_mapeo = lv_tipo_mapeo
      AND    estado = 'A'
      ;

   CURSOR cur_User(pv_UserName VARCHAR2)
   IS
      SELECT user_id
      FROM   fnd_user
      WHERE  user_name = pv_UserName;

   CURSOR cur_Resp(pv_RespName VARCHAR2)
   IS
      SELECT responsibility_id
           , application_id
      FROM   fnd_responsibility_tl
      WHERE  responsibility_name = pv_RespName
      AND    language = USERENV('LANG');

   lv_Concurrent      VARCHAR2(255);
   lv_Name            VARCHAR2(255);
   lv_Application     VARCHAR2(255);
   lv_Desc            VARCHAR2(255);
   lv_User            VARCHAR2(255);
   lv_Responsibility  VARCHAR2(255);
   lv_UserId          VARCHAR2(255);
   lv_RespId          VARCHAR2(255);
   lv_RespAppId       VARCHAR2(255);
   ln_concReqId       NUMBER := 0;

   BEGIN

      EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''LATIN AMERICAN SPANISH''';

      dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > Inicia el proceso XXFA_SN_DATA_AF.ksh');

      FOR x IN cur_Mapeos
      LOOP

         IF x.entrada = 'CONCURRENTE'
         THEN
            lv_Concurrent  := x.salida1;
            lv_Application := x.salida2;
            lv_Desc        := x.salida3;
         ELSIF x.entrada = 'USUARIO'
         THEN
            lv_User := x.salida1;
         ELSIF x.entrada = 'RESPONSABILIDAD'
         THEN
            lv_Responsibility := x.salida1;
         END IF;

      END LOOP;

      BEGIN
         SELECT user_concurrent_program_name
         INTO   lv_Name
         FROM   apps.fnd_concurrent_programs_vl
         WHERE  concurrent_program_name =lv_Concurrent;
      EXCEPTION
         WHEN OTHERS THEN
            lv_Concurrent := NULL;
      END;

      dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||'Concurrent      => '|| lv_Concurrent);
      dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||'ConcurrentName  => '|| lv_Name);
      dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||'Application     => '|| lv_Application);
      dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||'User            => '|| lv_User);
      dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||'Responsibility  => '|| lv_Responsibility);

      IF  lv_Concurrent    IS NOT NULL
      AND lv_Application   IS NOT NULL
      AND lv_User          IS NOT NULL
      AND lv_Responsibility IS NOT NULL
      THEN

         OPEN  cur_User(lv_User);
         FETCH cur_User INTO lv_UserId;

         IF cur_User%NOTFOUND
         THEN
            lv_errbuf  :='Error al buscar al usuario => ' || lv_User || ' ' || SQLERRM;
            ln_retcode :='2';
            RAISE_APPLICATION_ERROR(-20000,TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||lv_errbuf);
         ELSE
            OPEN  cur_Resp(lv_Responsibility);
            FETCH cur_Resp INTO lv_RespId
                              , lv_RespAppId;
            IF cur_Resp%NOTFOUND
            THEN
               lv_errbuf  :='Error al buscar datos de responsabilidad => ' || lv_Responsibility || ' ' || SQLERRM;
               ln_retcode :='2';
               RAISE_APPLICATION_ERROR(-20001,TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||lv_errbuf);
            END IF;
            CLOSE cur_Resp;

         END IF;
         CLOSE cur_User;

      ELSE
         lv_errbuf  :='Error inesperado al obtener los datos del mapeo para '||lv_tipo_mapeo||' '||SQLERRM;
         ln_retcode :='2';
         RAISE_APPLICATION_ERROR(-20004,TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||lv_errbuf);
      END IF;

      fnd_global.apps_initialize(lv_UserId, lv_RespId, lv_RespAppId);

      lv_cia          := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_CIA');
      lv_plazas       := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_PLAZAS');
      lv_lista_crs    := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_LISTA_CRS');
      lv_distrito_id  := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_DISTRITO_ID');
      lv_giro_ef      := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_GIRO_EF');
      lv_categoria    := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_CATEGORIA');
      lv_sub_cat      := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_SUB_CAT');
      lv_familia      := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_FAMILIA');
      lv_clave_activo := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_CLAVE_ACTIVO');
      lv_tipo_activo  := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_TIPO_ACTIVO');
      lv_periodo      := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_PERIODO');
      lv_libro        := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_LIBRO');
      lv_divisor      := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PN_DIVISOR');
      lv_mostrarME    := XXFA_SN_FILE_OUT_API_PKG.get_mapeos_s1_fnc(LV_MAPEO,'PV_MOSTRARME');
      
      IF lv_cia IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_cia INTO lv_cia;
      END IF;
      
      IF lv_plazas IS NOT NULL
      THEN   
      EXECUTE IMMEDIATE lv_plazas INTO lv_plazas;
      END IF;
      
      IF lv_lista_crs IS NOT NULL
      THEN
      EXECUTE IMMEDIATE lv_lista_crs INTO lv_lista_crs;
      END IF;
      
      IF lv_distrito_id IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_distrito_id INTO lv_distrito_id;
      END IF;
      
      IF lv_giro_ef IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_giro_ef INTO lv_giro_ef;
      END IF;
      
      IF lv_categoria IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_categoria INTO lv_categoria;
      END IF;
      
      IF lv_sub_cat IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_sub_cat INTO lv_sub_cat;
      END IF;
      
      IF lv_familia IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_familia INTO lv_familia;
      END IF;
      
      IF lv_clave_activo IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_clave_activo INTO lv_clave_activo;
      END IF;
      IF lv_tipo_activo IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_tipo_activo INTO lv_tipo_activo;
      END IF;
      
      IF lv_periodo IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_periodo INTO lv_periodo;
      END IF;
      
      IF lv_libro IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_libro INTO lv_libro;
      END IF;
      
      IF lv_divisor IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_divisor INTO ln_divisor;
      END IF;
      
      IF lv_mostrarME IS NOT NULL
      THEN
         EXECUTE IMMEDIATE lv_mostrarME INTO lv_mostrarME;
      END IF;
      
      ln_concReqId := fnd_request.submit_request( application => lv_Application
                                                , program     => lv_Concurrent
                                                , description => lv_Desc
                                                , start_time  => ''
                                                , sub_request => FALSE
                                                , argument1   => lv_cia
                                                , argument2   => lv_plazas
                                                , argument3   => lv_lista_crs
                                                , argument4   => lv_distrito_id
                                                , argument5   => lv_giro_ef
                                                , argument6   => lv_categoria
                                                , argument7   => lv_sub_cat
                                                , argument8   => lv_familia
                                                , argument9   => lv_clave_activo
                                                , argument10  => lv_tipo_activo
                                                , argument11  => lv_periodo
                                                , argument12  => lv_libro
                                                , argument13  => ln_divisor
                                                , argument14  => lv_mostrarME
                                                , argument15  => lv_origen
                                                ); 
      
      COMMIT;
      
      IF ln_concReqId <> 0
      THEN
         lv_errbuf  :='Se ejecuto el proceso correctamente bajo la solicitud => '|| ln_concReqId;
         ln_retcode :='0';
         dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||'Request Id      => '|| ln_concReqId);
      ELSE
         lv_errbuf  :='Ocurrio un error al ejecutar el proceso '||lv_Concurrent;
         ln_retcode :='1';
         dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||lv_errbuf);
      END IF;
      
      DBMS_OUTPUT.put_line('--------------------------------------------------------------');
      DBMS_OUTPUT.put_line('   Sociedad Anonima     : '||lv_cia         );
      DBMS_OUTPUT.put_line('   Lista de plazas      : '||lv_plazas      );
      DBMS_OUTPUT.put_line('   Lista de Crs         : '||lv_lista_crs   );
      DBMS_OUTPUT.put_line('   Distrito             : '||lv_distrito_id );
      DBMS_OUTPUT.put_line('   Giro                 : '||lv_giro_ef     );
      DBMS_OUTPUT.put_line('   Cuenta               : '||lv_categoria   );
      DBMS_OUTPUT.put_line('   Subcuenta            : '||lv_sub_cat     );
      DBMS_OUTPUT.put_line('   Familia              : '||lv_familia     );
      DBMS_OUTPUT.put_line('   Clave Activo         : '||lv_clave_activo);
      DBMS_OUTPUT.put_line('   Tipo de activo       : '||lv_tipo_activo );
      DBMS_OUTPUT.put_line('   Periodo              : '||lv_periodo     );
      DBMS_OUTPUT.put_line('   Libro Contable       : '||lv_libro       );
      DBMS_OUTPUT.put_line('   Divisor              : '||ln_divisor     );
      DBMS_OUTPUT.put_line('   Mostrar Categoria ME : '||lv_mostrarME   );
      DBMS_OUTPUT.put_line('--------------------------------------------------------------');


      dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > Termina el proceso XXFA_SN_DATA_AF.ksh');
            
EXCEPTION 
   WHEN OTHERS THEN
      lv_errbuf  :='Ocurrio un error el proceso XXFA_SN_DATA_AF '||'SQLERRM : '||SQLERRM;
      dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||lv_errbuf);
END;
/
EOF
echo "==============> Termina Proceso: $(date) <=============="