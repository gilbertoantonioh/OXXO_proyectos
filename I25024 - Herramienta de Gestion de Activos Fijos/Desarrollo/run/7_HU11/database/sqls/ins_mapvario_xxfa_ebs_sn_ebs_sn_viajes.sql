SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT INSERT MAPEO VARIO XXFA_EBS_SN - EBS_SN_VIAJES
DECLARE
   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
BEGIN

   DELETE xxfc_mapeos_varios
   WHERE  tipo_mapeo = 'XXFA_EBS_SN'
   AND    entrada    = 'EBS_SN_VIAJES'
   ;

   dbms_output.put_line('Se inserta registro en tabla de Mapeos Varios  XXFA_EBS_SN-EBS_SN_VIAJES');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN'
                                    ,p_entrada   => 'EBS_SN_VIAJES'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'ebs_sn_viaje'
                                    ,p_salida2   => 'xxfa_sn_trips_v'
                                    ,p_salida3   => 'sn_trip_id'
                                    ,p_salida4   => 'SELECT'
                                    ,p_salida5   => 'sn_trip_id,wst_trip_name,msi_item_description,msi_item_number,wdd_shipped_quantity,ooh_order_number,ooh_header_id,ool_line_id,ship_confirm_flag,wnd_confirm_date_yyyymmdd,plaza_destino,cr_destino,solicitante,solicitud_inversion'
                                    ,p_salida8   => 'sn_trip_name_ver'
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
      dbms_output.put_line('Eror al insertar registro en tabla de Mapeos Varios  XXFA_EBS_SN-EBS_SN_VIAJES: '||SQLERRM);      
END;   
/