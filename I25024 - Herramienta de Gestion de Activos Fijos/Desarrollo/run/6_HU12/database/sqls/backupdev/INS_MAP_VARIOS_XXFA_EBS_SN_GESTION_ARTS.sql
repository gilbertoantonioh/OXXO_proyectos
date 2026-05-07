SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT INSERT MAPEO VARIO XXFA_EBS_SN_GEST_ACTVS
DECLARE
   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
BEGIN

   DELETE xxfc_mapeos_varios
   WHERE  tipo_mapeo = 'XXFA_EBS_SN_GEST_ACTVS';
   --AND    entrada    LIKE 'EBS_SN_GESTION%';
   
   DELETE xxfc_mapeos_varios
   WHERE  tipo_mapeo = 'XXFA_EBS_SN_DIARIO'
   AND    entrada = 'XXFA_EBS_SN_GESTION_ARTS_PKG';
   
   DELETE xxfc_mapeos_varios
   WHERE  tipo_mapeo = 'XXFA_EBS_SN_GESTION_ARTS_PKG';
   --AND    entrada    LIKE 'EBS_SN_GESTION%';

   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_GEST_ACTVS'
                                    ,p_entrada   => 'EBS_SN_GESTION_IND'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'ebs_sn_gestion_independientes' -- Se debe concatenar con _yyyy_mm_dd
                                    ,p_salida2   => 'XXFA_EBS_SN_GESTION_INDEP_T'
                                    ,p_salida3   => NULL
                                    ,p_salida4   => 'SELECT'
                                    ,p_salida5   => 'MSI_ITEM_NUMBER, MSI_DESCRIPTION, CVE_FAMILIA, DESC_FAMILIA, SERIABLE, PLAQUEABLE, PROVEEDOR, RFC'
                                    ,p_salida6   => 'clave_articulo, descripcion_articulo, clave_familia, descripcion_familia, seriable, plaqueable, nombre_proveedor, rfc_proveedor'
                                    ,p_salida8   => 'NULL'
                                    ,p_salida9   => 'XXFA_SN_FILE_OUT_DIR'
                                    ,p_salida10  => 'XXFA_SN_FILE_OUT_PROC_DIR'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );                                    
                                    
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_GEST_ACTVS'
                                    ,p_entrada   => 'EBS_SN_GESTION_GPOS'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'ebs_sn_gestion_grupos' -- Se debe concatenar con _yyyy_mm_dd
                                    ,p_salida2   => 'XXFA_EBS_SN_GESTION_GRUPOS_T'
                                    ,p_salida3   => NULL
                                    ,p_salida4   => 'SELECT'
                                    ,p_salida5   => 'MSI_ITEM_NUMBER, MSI_DESCRIPTION, CVE_FAMILIA, DESC_FAMILIA, CVE_GRUPO, DESC_GRUPO, SERIABLE, PLAQUEABLE, PROVEEDOR, RFC'
                                    ,p_salida6   => 'clave_articulo, descripcion_articulo, clave_familia, descripcion_familia, clave_grupo, descripcion_grupo, seriable, plaqueable, nombre_proveedor, rfc_proveedor'
                                    ,p_salida8   => 'NULL'
                                    ,p_salida9   => 'XXFA_SN_FILE_OUT_DIR'
                                    ,p_salida10  => 'XXFA_SN_FILE_OUT_PROC_DIR'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );    
                                    
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_GEST_ACTVS'
                                    ,p_entrada   => 'EBS_SN_GESTION_KITS'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'ebs_sn_gestion_kits' -- Se debe concatenar con _yyyy_mm_dd
                                    ,p_salida2   => 'XXFA_EBS_SN_GESTION_KITS_T'
                                    ,p_salida3   => NULL
                                    ,p_salida4   => 'SELECT'
                                    ,p_salida5   => 'MSI_ITEM_NUMBER, MSI_DESCRIPTION, MSI_PARENT_MAND, CVE_FAMILIA, DESC_FAMILIA, CVE_KIT, DESC_KIT, MSI_ITEM_PRINCIPAL, SERIABLE, PLAQUEABLE, KITS, PROVEEDOR, RFC'
                                    ,p_salida6   => 'clave_articulo, descripcion_articulo, parent, clave_familia, descripcion_familia, nombre_kit, descripcion_kit, principal, seriable, plaqueable, kits, nombre_proveedor, rfc_proveedor'
                                    ,p_salida8   => 'NULL'
                                    ,p_salida9   => 'XXFA_SN_FILE_OUT_DIR'
                                    ,p_salida10  => 'XXFA_SN_FILE_OUT_PROC_DIR'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_GEST_ACTVS'
                                    ,p_entrada   => 'EBS_SN_GEST_PARAM_ORGSID1'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => '93' -- Ids de los almacenes                                   
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );      
                                    
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_DIARIO'
                                    ,p_entrada   => 'XXFA_EBS_SN_GESTION_ARTS_PKG'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => NULL                                  
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );      
                                    
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_GESTION_ARTS_PKG'
                                    ,p_entrada   => 'USUARIO'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'INTERFACES-POINV'                                  
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );                                         
                                    
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_GESTION_ARTS_PKG'
                                    ,p_entrada   => 'RESPONSABILIDAD'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'MXOXXO-PO17FAA-INTERFACES'                                  
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );     
                                    
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN_GESTION_ARTS_PKG'
                                    ,p_entrada   => 'CONCURRENTE'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'XXFA_EBS_SN_GESTION_ARTS_PKG'
                                    ,p_salida2   => 'XXFC'
                                    ,p_salida3   => 'XXFA - SN Gestion de activos EBS SN'
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