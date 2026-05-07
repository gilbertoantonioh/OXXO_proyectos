SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT INSERT MAPEO VARIO XXFA_EBS_SN - EBS_SN_VIAJES_COMP
DECLARE
   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
BEGIN

   DELETE xxfc_mapeos_varios
   WHERE  tipo_mapeo = 'XXFA_EBS_SN'
   AND    entrada    = 'EBS_SN_VIAJES_COMP'
   ;

   dbms_output.put_line('Se inserta registro en tabla de Mapeos Varios  XXFA_EBS_SN-EBS_SN_VIAJES_COMP');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN'
                                    ,p_entrada   => 'EBS_SN_VIAJES_COMP'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'ebs_sn_complementa_viaje'
                                    ,p_salida2   => 'xxfa_sn_trips_comp_grp_v'
                                    ,p_salida3   => 'wst_trip_name'
                                    ,p_salida4   => 'SELECT'
                                    ,p_salida5   => 'wst_trip_name,nombre_fletera,nombre_transportista,no_placa,organization_id'
                                    ,p_salida8   => 'wst_trip_name'
                                    ,p_salida9   => 'XXFA_SN_FILE_OUT_DIR'
                                    ,p_salida10  => 'XXFA_SN_FILE_OUT_PROC_DIR'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   COMMIT;
   dbms_output.put_line(lv_cadena);
EXCEPTION 
   WHEN OTHERS THEN
      ROLLBACK;
      dbms_output.put_line('Eror al insertar registro en tabla de Mapeos Varios  XXFA_EBS_SN-EBS_SN_VIAJES_COMP: '||SQLERRM);      
END;   
/