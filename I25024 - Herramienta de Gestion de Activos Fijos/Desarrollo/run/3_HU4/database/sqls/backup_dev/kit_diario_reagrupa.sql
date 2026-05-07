            set serveroutput on 
			DECLARE 
               lv_x_errors         VARCHAR2(4000)  := NULL; 
               ln_x_retcode        NUMBER  := NULL;    
               le_no_exception     EXCEPTION; 			   
               lv_ooh_order_number VARCHAR2(50)  := '202342';
  			   ln_ool_line_id      NUMBER  := '6557122'; 
			BEGIN 

               ln_x_retcode := NULL;  
               lv_x_errors := NULL;  
               
               dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
               XXINV_KITS_CUENTAS_DIARIO.reagrupa_info_prc( pn_ooh_order_number   => lv_ooh_order_number
                                                          , pn_ool_line_id        => ln_ool_line_id
                                                          , pv_retcode            => ln_x_retcode
                                                          , pv_errors             => lv_x_errors   
                                                             );
                                           
               IF ln_x_retcode != 0
               THEN 
                  fnd_file.put_line(fnd_file.LOG, 'Error eliminando registros temporales en xxinv_pre_material_trx_temp: '|| lv_x_errors);              
                  RAISE le_no_exception;
               END IF;
            
               COMMIT; 
               fnd_file.put_line(fnd_file.LOG, 'Se eliminaron registros temporales en xxinv_pre_material_trx_temp.');
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');                                                      
            EXCEPTION      
               WHEN le_no_exception THEN 
                  ROLLBACK;
                  RAISE;    
               WHEN OTHERS THEN
                  dbms_output.put_line( 'Error actualizando las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas, others. Error: '||SQLERRM); 
                  ROLLBACK;    
                  RAISE; 
            END;