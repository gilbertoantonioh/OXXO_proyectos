/******************************************************************************************************************
* Modulo      : Insert Mapeo
* Autor       : Fabiola Sanchez
* Fecha       : 18-SEP-2025
* Descripcion : CHG0113891 Inserta informacion de seteo para la ejecucion mediante shell del concurrente
*               
*
* Modificado Por        Fecha           Codigo        Descripcion
------------------------------------------------------------------------------------------------------------------
* Fabiola Sanchez      18-SEP-2025      CHG0113891    Generacion del script
*******************************************************************************************************************/
DECLARE

   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
   
   

BEGIN

   dbms_output.put_line('Se insertan Usuario en tabla de Mapeos Varios  ');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_FILE_OUT'
                                    ,p_entrada   => 'USUARIO'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'INTERFACES-POINV'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);
      
   dbms_output.put_line('Se insertan responsabilidad en tabla de Mapeos Varios ');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_FILE_OUT'
                                    ,p_entrada   => 'RESPONSABILIDAD'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'MXOXXO-PO17FAA-INTERFACES'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);
   
   dbms_output.put_line('Se inserta informacion de concurrente de Reporte de Pago de Nacionales en tabla de Mapeos Varios ');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_FILE_OUT'
                                    ,p_entrada   => 'CONCURRENTE'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'XXFA_SN_FILE_OUT_API_PKG'
                                    ,p_salida2   => 'XXFC'
                                    ,p_salida3   => 'XXFA - SN Generacion de Archivos de Integracion'
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