SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT INSERT MAPEO VARIO XXFA_SN_WSH_PURGE_TRIPS
DECLARE

   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
   
   

BEGIN
   delete xxfc_mapeos_varios
   where tipo_mapeo = 'XXFA_SN_WSH_PURGE_TRIPS'
   ;

   dbms_output.put_line('Se insertan Usuario en tabla de Mapeos Varios  ');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_SN_WSH_PURGE_TRIPS'
                                    ,p_entrada   => 'USUARIO'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'INTERFACES-POINV'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);
      
   dbms_output.put_line('Se insertan responsabilidad en tabla de Mapeos Varios ');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_SN_WSH_PURGE_TRIPS'
                                    ,p_entrada   => 'RESPONSABILIDAD'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'MXOXXO-PO17FAA-INTERFACES'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);
   
   dbms_output.put_line('Se inserta informacion de concurrente XXFA - SN Depura Informacion de Viajes WSH ');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_SN_WSH_PURGE_TRIPS'
                                    ,p_entrada   => 'CONCURRENTE'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'XXFA_SN_WSH_PURGE_TRIPS'
                                    ,p_salida2   => 'XXFC'
                                    ,p_salida3   => 'XXFA - SN Depura Informacion de Viajes WSH'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);
      
   COMMIT;
  
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line('Error inesperado al insertar mapeo. Detalle: ' || SQLERRM);
      ROLLBACK;
END;
/