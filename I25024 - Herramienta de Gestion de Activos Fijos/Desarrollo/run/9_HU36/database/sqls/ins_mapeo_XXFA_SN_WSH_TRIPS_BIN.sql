SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT INSERT MAPEO VARIO XXFA_SN_WSH_TRIPS_BIN
DECLARE

   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
BEGIN

   DELETE xxfc_mapeos_varios
   WHERE  tipo_mapeo = 'XXFA_SN_WSH_TRIPS_BIN'
   ;

   dbms_output.put_line('Mapeo XXFA_SN_WSH_TRIPS_BIN, Se inserta Usuario INTERFACES-POINV en tabla de Mapeos Varios  ');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_SN_WSH_TRIPS_BIN'
                                    ,p_entrada   => 'USUARIO'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'INTERFACES-POINV'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);
      
   dbms_output.put_line('Mapeo XXFA_SN_WSH_TRIPS_BIN, Se inserta responsabilidad MXOXXO-PO17FAA-INTERFACES en tabla de Mapeos Varios ');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_SN_WSH_TRIPS_BIN'
                                    ,p_entrada   => 'RESPONSABILIDAD'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'MXOXXO-PO17FAA-INTERFACES'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);
   
   dbms_output.put_line('Mapeo XXFA_SN_WSH_TRIPS_BIN, Se inserta informacion de concurrente XXFA - SN Actualiza Informacion de Viajes WSH ');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_SN_WSH_TRIPS_BIN'
                                    ,p_entrada   => 'CONCURRENTE'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'XXFA_SN_WSH_TRIPS'
                                    ,p_salida2   => 'XXFC'
                                    ,p_salida3   => 'XXFA - SN Actualiza Informacion de Viajes WSH'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);
      
   COMMIT;
  
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line('Error inesperado al insertar mapeo XXFA_SN_WSH_TRIPS_BIN. Detalle: ' || SQLERRM);
      ROLLBACK;
END;
/