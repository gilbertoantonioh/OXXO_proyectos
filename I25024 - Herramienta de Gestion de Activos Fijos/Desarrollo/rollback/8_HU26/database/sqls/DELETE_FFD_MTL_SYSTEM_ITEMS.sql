SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT Eliminando Flexfield Descriptivo en MTL_SYSTEM_ITEMS columnas ATTRIBUTE13, ATTRIBUTE16 y ATTRIBUTE17
DECLARE
   ln_request_id  NUMBER;
   
BEGIN
   FOR c IN (SELECT ffdcu.application_id
                  , ffdcu.descriptive_flexfield_name
                  , ffdcu.descriptive_flex_context_code
                  , ffdcu.application_column_name
             FROM   fnd_descr_flex_column_usages ffdcu
             WHERE  ffdcu.descriptive_flexfield_name    = 'MTL_SYSTEM_ITEMS'
             AND    ffdcu.application_column_name        IN ('ATTRIBUTE13', 'ATTRIBUTE16', 'ATTRIBUTE17')
             )
   LOOP
      fnd_descr_flex_col_usage_pkg.delete_row(x_application_id                => c.application_id
                                            , x_descriptive_flexfield_name    => c.descriptive_flexfield_name
                                            , x_descriptive_flex_context_cod  => c.descriptive_flex_context_code
                                            , x_application_column_name       => c.application_column_name
                                              );
   
      dbms_output.put_line('Se elimino el Flexfield Descriptivo en MTL_SYSTEM_ITEMS columna '||c.application_column_name);
   END LOOP;
   
   dbms_output.put_line('Se confirma la eliminacion del Flexfield Descriptivo en MTL_SYSTEM_ITEMS columnas ATTRIBUTE13, ATTRIBUTE16 y ATTRIBUTE17.');
   COMMIT;  
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      dbms_output.put_line('Error al eliminar el Flexfield Descriptivo en MTL_SYSTEM_ITEMS columnas ATTRIBUTE13, ATTRIBUTE16 y ATTRIBUTE17. Se hace rollback. Error: '|| SQLERRM);
END;
/

