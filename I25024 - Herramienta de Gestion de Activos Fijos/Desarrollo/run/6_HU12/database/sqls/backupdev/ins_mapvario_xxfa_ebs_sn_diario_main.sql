SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT INSERT MAPEO VARIO XXFA_EBS_SN_DIARIO_MAIN
DECLARE

   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
   
   

BEGIN
   delete xxfc_mapeos_varios
   where tipo_mapeo = 'XXFA_EBS_SN_DIARIO_MAIN'
   ;

   dbms_output.put_line('Se insertan Usuario en tabla de Mapeos Varios  ');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_DIARIO_MAIN'
                                    ,p_entrada   => 'DIA_EBS_SN_SALIDAS'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'XXFA_EBS_SN'
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