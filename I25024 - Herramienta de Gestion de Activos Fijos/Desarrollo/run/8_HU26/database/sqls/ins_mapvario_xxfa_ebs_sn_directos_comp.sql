SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT INSERT MAPEO VARIO XXFA_EBS_SN - EBS_SN_DIRECTOS
DECLARE
   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
BEGIN

   DELETE xxfc_mapeos_varios
   WHERE  tipo_mapeo = 'XXFA_EBS_SN'
   AND    entrada    = 'EBS_SN_DIRECTOS'
   ;

   dbms_output.put_line('Se inserta registro en tabla de Mapeos Varios  XXFA_EBS_SN-EBS_SN_DIRECTOS');
   xxfc_utl_pub_pkg.insertamapeo_prc(p_tipomapeo => 'XXFA_EBS_SN'
                                    ,p_entrada   => 'EBS_SN_DIRECTOS'
                                    ,p_estado    => 'A'
                                    ,p_salida1   => 'ebs_sn_directos'
                                    ,p_salida2   => 'xxfa_sn_data_rcv_oth_direcs_v'
                                    ,p_salida3   => 'rcv_transaction_id'
                                    ,p_salida4   => 'SELECT'
                                    ,p_salida5   => 'rcv_transaction_id,sn_transaction_id,rcv_source_code,rcv_transaction_date,rsh_receipt_num,msi_item_number,msi_use_type,msi_fa_code,rsl_item_description,msi_sat_code,msi_asset_badgeable_flag,msi_asset_seriable_flag'
                                    ,p_salida6   => ',msi_cfdi_use,mic_item_categ_fam,mic_item_categ_subfam ,fcb_asset_categ_descr,fcb_asset_categ,fcb_asset_subcateg,fcb_asset_categ_fam,fcb_asset_categ_fakey,rcv_quantity,rcv_po_unit_price,rcv_currency_code'
                                    ,p_salida7   => ',rcv_currency_conversion_rate,ap_org_company_name,ap_org_company_rfc,pol_oracle_cia,pol_oracle_ef,pol_oracle_cr_superior,pol_oracle_cr,poh_po_number,pra_release_num,asu_vendor_number,asu_vendor_name,rcv_invoice_num'
                                    ,p_salida8   => 'rsh_receipt_num'
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
      dbms_output.put_line('Eror al insertar registro en tabla de Mapeos Varios  XXFA_EBS_SN-EBS_SN_DIRECTOS: '||SQLERRM);      
END;   
/