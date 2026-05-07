            set serveroutput on 
			DECLARE 
               lv_x_errors         VARCHAR2(4000)  := NULL; 
               ln_x_retcode        NUMBER  := NULL;    
               le_no_exception     EXCEPTION; 			   
               lv_ooh_order_number VARCHAR2(50)  := '202342';
  			   ln_ool_line_id      NUMBER  := '6557122'; 
			BEGIN 
               dbms_output.put_line( 'Actualizando referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas para el pedido de movimiento: '||lv_ooh_order_number||' id de linea de pedido de movimiento: '||ln_ool_line_id);
               
               dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');               
               XXINV_KITS_CUENTAS_DIARIO.xxinv_mat_trx_prc( pn_ooh_order_number   => lv_ooh_order_number
                                                          , pn_ool_line_id        => ln_ool_line_id
                                                          , pn_x_ret_code         => ln_x_retcode
                                                          , pv_x_errors           => lv_x_errors   
                                                             );
                                                             
               IF ln_x_retcode != 0
               THEN 
                  dbms_output.put_line( 'Error actualizando referencias en xxinv_material_trx_temp: '|| lv_x_errors);  
                  RAISE le_no_exception;
               END IF;
 
               dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '); 
               COMMIT; 
               
               ln_x_retcode := NULL;  
               lv_x_errors := NULL;  
               
               dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
               XXINV_KITS_CUENTAS_DIARIO.pre_xxinv_mat_trx_temp_prc( pn_ooh_order_number   => lv_ooh_order_number
                                                                   , pn_ool_line_id        => ln_ool_line_id
                                                                   , pv_retcode            => ln_x_retcode
                                                                   , pv_errors             => lv_x_errors   
                                                                     );   

               IF ln_x_retcode != 0
               THEN 
                  dbms_output.put_line( 'Error actualizando referencias en xxinv_pre_material_trx_temp: '|| lv_x_errors);   
                  RAISE le_no_exception;
               END IF;
               
               dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');            
               COMMIT; 
               ln_x_retcode := NULL;  
               lv_x_errors := NULL;  
               
               dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
               XXINV_KITS_CUENTAS_DIARIO.procesa_info_articulo_prc( pn_ooh_order_number   => lv_ooh_order_number
                                                                  , pn_ool_line_id        => ln_ool_line_id
                                                                  , pv_retcode            => ln_x_retcode
                                                                  , pv_errors             => lv_x_errors   
                                                                    );
                                           
               IF ln_x_retcode != 0
               THEN 
                  dbms_output.put_line( 'Error actualizando referencias en xxfc_sn_escaneo_lineas: '|| lv_x_errors);       
                  RAISE le_no_exception;
               END IF;
                        
               COMMIT;  
               dbms_output.put_line( 'Se actualizaron las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas.');
               dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');                                                      
            EXCEPTION      
               WHEN le_no_exception THEN 
                  ROLLBACK;
                  RAISE;    
               WHEN OTHERS THEN
                  dbms_output.put_line( 'Error actualizando las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas, others. Error: '||SQLERRM); 
                  ROLLBACK;    
                  RAISE; 
            END;