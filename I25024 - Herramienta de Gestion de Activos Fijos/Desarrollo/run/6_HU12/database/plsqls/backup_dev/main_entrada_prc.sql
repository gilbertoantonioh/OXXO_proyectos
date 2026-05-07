   /********************************************************************************************
   Modulo : main_entrada_prc
   Autor : Fabiola Sanchez (Hexaware)
   Fecha : 15/Sep/2025
   Descripcion : Procedimiento inicial llamado en el concurrente XXFA - SN  Generacion de Archivos de Integracion Principal
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  13/Ene/2026   CHG0137347     Version Inicial
   ********************************************************************************************/   
   
   PROCEDURE main_entrada_prc(errbuf        OUT VARCHAR2
                             ,retcode       OUT VARCHAR2
                                )
   IS

      CURSOR cur_main(pv_map VARCHAR2
                         ,pv_ent VARCHAR2)
      IS
         SELECT entrada
              , salida1 
         FROM   apps.xxfc_mapeos_varios xmv
         WHERE  UPPER(tipo_mapeo) = 'XXFA_EBS_SN_DIARIO_MAIN'
         AND    xmv.estado           = 'A'
         AND  ( xmv.fecha_inicial    <= SYSDATE OR xmv.fecha_inicial IS NULL )
         AND  ( xmv.fecha_final      >= SYSDATE OR xmv.fecha_final IS NULL )
         ORDER BY mapeo_id;

   BEGIN
      fnd_file.put_line(fnd_file.LOG, 'Inicia main_entrada_prc: '||TO_CHAR(SYSDATE,'DD:MM:RRRR HH24:MI:SS'));
      fnd_file.put_line(fnd_file.LOG, '');
      

      
      FOR cA IN cur_main
      LOOP
         BEGIN 
            fnd_file.put_line(fnd_file.LOG, CHR(10)||'+---------------------------------------------------------------------------+');
            fnd_file.put_line(fnd_file.LOG, 'pv_tipo_mapeo: '||cA.salida1);
            fnd_file.put_line(fnd_file.LOG, 'pv_entrada: '||cA.entrada);
		    
		    
            inicio_entrada_prc(errbuf          => errbuf
                              ,retcode         => retcode
                              ,pv_tipo_mapeo   => cA.salida1
                              ,pv_entrada      => cA.entrada
                               )
                               ;
	     EXCEPTION 
            WHEN OTHERS THEN 
               fnd_file.put_line(fnd_file.LOG, '');
               fnd_file.put_line(fnd_file.LOG, 'Error ejecutando inicio_entrada_prc: '||SQLERRM||' '||TO_CHAR(SYSDATE,'DD:MM:RRRR HH24:MI:SS'));			
         END; 			
      END LOOP;

      fnd_file.put_line(fnd_file.LOG, '');
      fnd_file.put_line(fnd_file.LOG, 'Finaliza main_entrada_prc: '||TO_CHAR(SYSDATE,'DD:MM:RRRR HH24:MI:SS'));
   END main_entrada_prc;