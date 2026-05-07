SET DEFINE OFF;
PROMPT ALTER TABLE xxfc.xxfc_sn_escaneo_lineas DROP columns wsh_sts_header_id, wsh_sts_line_id
ALTER TABLE xxfc.xxfc_sn_escaneo_lineas DROP (wsh_sts_header_id  
                                            , wsh_sts_line_id    
										     );