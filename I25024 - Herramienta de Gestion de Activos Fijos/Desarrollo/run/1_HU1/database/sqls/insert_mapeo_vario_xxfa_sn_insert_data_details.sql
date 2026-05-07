SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT INSERTA XXFC_MAPEOS_VARIOS XXFA_SN_INSERT_DATA_DETAILS

DECLARE

   ln_Salida          NUMBER;
   lv_Cadena          VARCHAR2(250);
   ln_MapeoIdSuperior NUMBER;
   
BEGIN   
   DELETE XXFC_MAPEOS_VARIOS
   WHERE  tipo_mapeo = 'XXFA_SN_INSERT_DATA_DETAILS'
   ;
   
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_SN_INSERT_DATA_DETAILS'
                                   , p_entrada   => 'USE_ITEM_04'
								   , p_fechainicial => TO_DATE('01/10/2021','DD/MM/YYYY')
                                   , p_estado    => 'A'
								   , p_salida1   => '04'
                                   , x_salida    => ln_salida
                                   , x_cadena    => lv_cadena);

   dbms_output.put_line(lv_cadena);


   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_SN_INSERT_DATA_DETAILS'
                                   , p_entrada   => 'RCV_TRX_TYPE_RECEIVE'
								   , p_fechainicial => TO_DATE('01/10/2021','DD/MM/YYYY')
                                   , p_estado    => 'A'
								   , p_salida1   => 'RECEIVE'
                                   , x_salida    => ln_salida
                                   , x_cadena    => lv_cadena);

   dbms_output.put_line(lv_cadena);

   
   COMMIT;
   
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line('Error inesperado al insertar mapeo. Detalle: ' || SQLERRM);
      
      ROLLBACK;
      
END;
/