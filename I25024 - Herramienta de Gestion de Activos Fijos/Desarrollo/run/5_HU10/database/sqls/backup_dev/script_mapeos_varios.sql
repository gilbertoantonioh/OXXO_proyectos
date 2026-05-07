/******************************************************************************************************************
* Modulo      : 
* Autor       : 
* Fecha       : 15-SEP-2025
* Descripcion : Inserta informacion 
*               
*
* Modificado Por        Fecha           Codigo        Descripcion
------------------------------------------------------------------------------------------------------------------

*******************************************************************************************************************/
DECLARE

   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
   
   

BEGIN

   dbms_output.put_line('Se inserta en tabla de Mapeos Varios  EBS_SN_ENTRADA');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN'
                                    ,p_entrada   => 'EBS_SN_ENTRADA'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'ebs_sn_entrada'
                                    ,p_salida2   => 'xxfa_sn_data_details'
                                    ,p_salida3   => 'data_detail_id'
                                    ,p_salida4   => 'SELECT'
                                    ,p_salida5   => 'data_detail_id,msi_asset_badgeable_flag,msi_asset_seriable_flag,rcv_invoice_num,rcv_po_unit_price,rcv_quantity,msi_item_number,mic_item_categ_fam,mic_item_categ_subfam,msi_use_type,asu_vendor_name,asu_vendor_number,ap_org_company_name,'
                                    ,p_salida6   => 'ap_org_company_rfc,msi_kit_type,msi_kit_principal_flag,msi_kit_parent,rcv_transaction_date,rsh_receipt_num,CASE WHEN pra_release_num IS NOT NULL THEN poh_po_number||''-''||pra_release_num ELSE poh_po_number END AS poh_po_number'
                                    ,p_salida8   => 'rsh_receipt_num'
                                    ,p_salida9   => 'XXFA_SN_FILE_OUT_DIR'
                                    ,p_salida10  => 'XXFA_SN_FILE_OUT_PROC_DIR'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);

   dbms_output.put_line('Se inserta en tabla de Mapeos Varios  EBS_SN_PRESAL');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN'
                                    ,p_entrada   => 'EBS_SN_PRESAL'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'ebs_sn_previo_salida'
                                    ,p_salida2   => 'xxfa_sn_data_details'
                                    ,p_salida3   => 'data_detail_id'
                                    ,p_salida4   => 'SELECT'
                                    ,p_salida5   => 'data_detail_id,prl_oracle_cia,prl_oracle_ef,prl_oracle_cr_superior,prl_oracle_cr_sup_descr,prl_retek_distrito,prl_oracle_cr,prl_oracle_cr_descr,wst_trip_name'
                                    ,p_salida8   => 'wst_trip_name'
                                    ,p_salida9   => 'XXFA_SN_FILE_OUT_DIR'
                                    ,p_salida10  => 'XXFA_SN_FILE_OUT_PROC_DIR'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);
      
   dbms_output.put_line('Se inserta en tabla de Mapeos Varios  EBS_SN_POSSAL');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN'
                                    ,p_entrada   => 'EBS_SN_POSSAL'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'ebs_sn_posterior_salida'
                                    ,p_salida2   => 'xxfa_sn_data_details'
                                    ,p_salida3   => 'data_detail_id'
                                    ,p_salida4   => 'SELECT'
                                    ,p_salida5   => 'data_detail_id,faa_asset_number,fcb_asset_categ_acct,fcb_asset_categ_subacct,fcb_asset_categ_fam,fcb_asset_categ_fakey,fbk_date_placed_mm,fbk_date_placed_yyyy,faa_property_type_code,faa_description,faa_manufacturer_name,'
                                    ,p_salida6   => 'faa_model_number,faa_serial_number'
                                    ,p_salida8   => '-faa_asset_number'
                                    ,p_salida9   => 'XXFA_SN_FILE_OUT_DIR'
                                    ,p_salida10  => 'XXFA_SN_FILE_OUT_PROC_DIR'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);
   
   dbms_output.put_line('Se inserta en tabla de Mapeos Varios  EBS_SN_FE');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN'
                                    ,p_entrada   => 'EBS_SN_FE'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'ebs_sn_validacion_fiscal'
                                    ,p_salida2   => 'xxfa_sn_fe_data_details'
                                    ,p_salida3   => 'fe_data_detail_id'
                                    ,p_salida4   => 'SELECT'
                                    ,p_salida5   => 'fe_data_detail_id,rsh_receipt_num,rcv_invoice_num,ap_org_company_rfc,ap_org_company_name,asu_vendor_number,asu_vendor_name,msi_item_number,rsl_item_description,rcv_quantity,rcv_po_unit_price,rcv_currency_code,rcv_currency_conversion_rate'
                                    ,p_salida8   => 'rsh_receipt_num'
                                    ,p_salida9   => 'XXFA_SN_FILE_OUT_DIR'
                                    ,p_salida10  => 'XXFA_SN_FILE_OUT_PROC_DIR'
                                    ,x_salida    => ln_salida
                                    ,x_cadena    => lv_cadena
                                    );
   dbms_output.put_line(lv_cadena);
   
END;   
/