SET DEFINE OFF;
PROMPT ALTER TABLE xxfc.xxfc_sn_escaneo_lineas ADD columns wsh_sts_header_id, wsh_sts_line_id
ALTER TABLE xxfc.xxfc_sn_escaneo_lineas ADD (wsh_sts_header_id   NUMBER 
                                           , wsh_sts_line_id     NUMBER 
										     );