SET DEFINE OFF;
PROMPT PACKAGE BODY XXFA_SN_PO_OTH_VALIDATE_PKG
CREATE OR REPLACE PACKAGE BODY apps.xxfa_sn_po_oth_validate_pkg 
AS 

   /********************************************************************************************
   * Modulo : XXFA_SN_PO_OTH_VALIDATE_PKG
   * Autor : Gilberto Hernandez (Hexaware) 
   * Version : 1.0
   * Fecha : 7/Abril/2025
   * Descripcion : Paquete para realizar las validaciones sobre otras compras de Activo Fijo como Cargos Directos o Virtuales, para confirmar que los datos
   *               son correctos para el flujo de EBS a Service Now. 
   *
   * Ejecutado Por :
   *
   * Ejecuciones :
   *
   * Modificado Por                 Fecha         Codigo          Descripcion
   * -------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  7/Abril/2025  CHG0145709      Version Inicial
   ********************************************************************************************/
   gv_errbuf      VARCHAR2(4000);  
   gv_retcode     VARCHAR2(1);  
   
   
   /********************************************************************************************
   Modulo : is_use_item_for_cd_fnc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 9/Abril/2025
   Descripcion : Valida si el uso del articulo es para para el proceso de Cargos Directos 
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  9/Abril/2025  CHG0145709      Version Inicial
   ********************************************************************************************/
   FUNCTION is_use_item_for_cd_fnc (pv_use_item IN VARCHAR2) 
   RETURN VARCHAR2    
   IS 
      ln_count NUMBER := 0; 
   BEGIN
      SELECT COUNT(1)
	  INTO   ln_count
      FROM   xxfc_mapeos_varios xmv
      WHERE  xmv.tipo_mapeo = 'XXFA_SN_PO_OTH_VALIDATE_CD'
      AND    xmv.entrada    LIKE 'USE_ITEM%'
      AND    xmv.salida1    = pv_use_item
      AND    xmv.estado     = 'A'
      AND    ( xmv.fecha_inicial < SYSDATE OR xmv.fecha_inicial IS NULL )
      AND    ( xmv.fecha_final > SYSDATE OR xmv.fecha_final IS NULL )
      ; 
	  
	  IF ln_count > 0
	  THEN 
	     RETURN 'Y'; 
	  ELSE 
	     RETURN 'N'; 
	  END IF; 
   
   EXCEPTION 
      WHEN OTHERS THEN 
	     RETURN 'E'; 
   END is_use_item_for_cd_fnc; 
   
   /********************************************************************************************
   Modulo : update_po_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 8/Abril/2025
   Descripcion : Actualizar la PO/Release indicando que se ejecuto la validacion  
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  8/Abril/2025  CHG0145709      Version Inicial
   ********************************************************************************************/
   PROCEDURE update_po_prc (  errbuf                     OUT VARCHAR2
                            , retcode                    OUT VARCHAR2
                            , p_poh_type_lookup_code     IN VARCHAR2
                            , p_po_id                    IN NUMBER
                            , p_validate_flag            IN VARCHAR2
                           )
   IS                          
                           

     ln_po_header_id          NUMBER; 
     lc_poh_type_lookup_code  po_headers_all.type_lookup_code%TYPE; 
     ln_po_release_id         NUMBER;   
   BEGIN 
      IF p_poh_type_lookup_code = 'STANDARD' 
      THEN
         UPDATE po_headers_all SET global_attribute20 = p_validate_flag
         WHERE  po_header_id = p_po_id
         ; 
      ELSIF p_poh_type_lookup_code = 'BLANKET' 
	  THEN
         UPDATE po_releases_all SET global_attribute20 = p_validate_flag
         WHERE  po_release_id = p_po_id
         ;    
      ELSE 
         NULL; 
      END IF; 
   
      IF SQL%ROWCOUNT = 1
      THEN 
         retcode := 0; 
         errbuf  := 'Se actualizo la PO/Release Id '||p_po_id||'. Bandera '||p_validate_flag||'.' ;       
      ELSE 
         retcode := 1; 
         errbuf  := 'No se actualizo la PO/Release Id '||p_po_id||'. RowCount '||SQL%ROWCOUNT||'.' ;          
      END IF;
   EXCEPTION 
      WHEN OTHERS THEN 
         retcode := '2';
         errbuf  := 'Error OTHERS xxfa_sn_po_oth_validate_pkg.update_po_prc: '||SQLERRM;    
   END update_po_prc;                    
   
   /********************************************************************************************
   Modulo : cd_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 7/Abril/2025
   Descripcion : Validar datos para compras de Activo Fijo de tipo Cargos Directos 
                 Ejecutado desde el programa concurrente: XXFA - SN Validacion de Orden de Compra Cargos Directos 
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  7/Abril/2025  CHG0145709      Version Inicial
   ********************************************************************************************/
   PROCEDURE cd_prc (  errbuf               OUT VARCHAR2
                     , retcode              OUT VARCHAR2
                     , p_po_header_id        IN NUMBER
                     , p_po_release_id       IN NUMBER
                     )
   IS   
     lc_vacio    VARCHAR2(15) := '*** VACIO ***'; 
     lb_po_found BOOLEAN      := FALSE;
     lb_warning  BOOLEAN      := FALSE; 
     
     handled_exception EXCEPTION; 
     
     ln_po_header_id          NUMBER; 
     lc_poh_type_lookup_code  po_headers_all.type_lookup_code%TYPE; 
     ln_po_id                 NUMBER;    
   
   
     CURSOR po_data( p_po_header_id        IN NUMBER
                   , p_po_release_id       IN NUMBER
                   )
     IS 
        WITH 
        fca AS
        (
        SELECT  fsa.alias_name
              , fca.category_id
              , fca.description
              , fca.segment1
              , fca.segment2
              , fca.segment3
              , fca.segment4 
        FROM    apps.fnd_shorthand_flex_aliases fsa
              , apps.fa_categories fca 
        WHERE   fsa.id_flex_code = 'CAT#'
        AND     fsa.concatenated_segments = fca.segment1 || '.' || fca.segment2 || '.' || fca.segment3 || '.' || fca.segment4 
        AND     fca.enabled_flag = 'Y'  
        )
        SELECT mtl.organization_id           AS mtl_organization_id 
             , mtl.organization_code         AS mtl_inv_organization_code
             , msi.inventory_item_id         AS msi_inventory_item_id
             , msi.segment1                  AS msi_item_number                              
             , msi.attribute1                AS msi_use_type                                 
             , msi.attribute2                AS msi_fa_code                                  
             , msi.attribute12               AS msi_sat_code                                                       
             , msi.attribute13               AS msi_cfdi_use     
             , msi.inventory_item_flag       AS msi_inventory_item_flag			 
             , fca.category_id               AS faa_asset_category_id
             , fca.description               AS fcb_asset_categ_descr                       
             , REPLACE(fca.segment1||'.'||fca.segment2||'.'||fca.segment3||'.'||fca.segment4, '...','') AS fcb_asset_categ_seg_concat                           
             , poh.po_header_id              AS poh_po_header_id
             , poh.segment1                  AS poh_po_number    
             , poh.type_lookup_code          AS poh_type_lookup_code     
             , pra.po_release_id             AS pra_po_release_id 
             , pra.release_num               AS pra_release_num                                    
             , pol.po_line_id                AS rcv_po_line_id
             , pol.line_num                  AS pol_po_line_num 
             , pol.attribute1                AS pol_oracle_ef                                 
             , pol.attribute2                AS pol_oracle_cr                                                            
        FROM   apps.mtl_system_items_b           msi     
             , apps.mtl_parameters               mtl
             , fca
             , apps.po_lines_all                 pol
             , apps.po_line_locations_all        pll
             , apps.po_headers_all               poh
             , apps.po_releases_all              pra 
        WHERE 1 = 1
        AND   pll.ship_to_organization_id   = mtl.organization_id
        AND   pll.ship_to_organization_id   = msi.organization_id   (+) 
        AND   pol.item_id                   = msi.inventory_item_id (+)    
        AND   msi.attribute2                = fca.alias_name        (+)     
        AND   poh.po_header_id              = pol.po_header_id 
        AND   pol.po_line_id                = pll.po_line_id  
        AND   pll.po_release_id             = pra.po_release_id     (+) 
        AND   poh.po_header_id              = p_po_header_id
        AND ( ( pra.po_release_id           = p_po_release_id AND poh.type_lookup_code = 'BLANKET') OR (poh.type_lookup_code = 'STANDARD') ) -- Si es despacho valida el parametro, si es standard no lo valida. 
        ORDER BY pol_po_line_num
        ;       
    
      -- Procedimiento para insertar en el buffer de error 
      PROCEDURE write_errbuf_prc (p_errbuf IN VARCHAR2)
      IS 
      BEGIN
         fnd_file.put_line(fnd_file.log, p_errbuf); 
         fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');    
         
         IF gv_errbuf IS NOT NULL 
         THEN 
		    IF p_errbuf NOT LIKE '%'||gv_errbuf||'%'
			THEN 
               gv_errbuf  := SUBSTR(gv_errbuf ||' '||p_errbuf, 1, 4000);  
            END IF;
		 ELSE 
            gv_errbuf  := SUBSTR(p_errbuf, 1, 4000);  
         END IF;      
      EXCEPTION 
         WHEN OTHERS THEN 
            gv_errbuf := 'Error OTHERS xxfa_sn_po_oth_validate_pkg.cd_prc.write_errbuf_prc: '||SQLERRM;          
      END write_errbuf_prc; 
      
   BEGIN 
      fnd_file.put_line(fnd_file.log, 'Ejecutando validacion de orden de compra aprobada previo a recepcion.'); 
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '); 
      
       --Validar perfil origen de recepcion de activos fijos 
      IF NOT (FND_PROFILE.value('XXFC_RCV_FA_ORIGENES') = 'DIRECTOS')   
      THEN 
         gv_retcode := '2';
         write_errbuf_prc('El perfil XXFC_RCV_FA_ORIGENES no tiene valor de DIRECTOS. No esta permitido ejecutar este programa desde esta responsabilidad.'); 
         RAISE handled_exception; 
      END IF; 

      fnd_file.put_line(fnd_file.log, 'Informacion de PO: '); 
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');         
      
      FOR po IN po_data( p_po_header_id    => p_po_header_id
                       , p_po_release_id   => p_po_release_id
                   )
      LOOP 
         IF NOT lb_po_found 
         THEN -- La primer vuelta del cursor  
            fnd_file.put_line(fnd_file.log, 'Orden de Compra: '||po.poh_po_number);
            fnd_file.put_line(fnd_file.log, 'Tipo: '||po.poh_type_lookup_code);
            fnd_file.put_line(fnd_file.log, 'No. Despacho: '||TO_CHAR(po.pra_release_num));
            
            ln_po_header_id             := po.poh_po_header_id;
            lc_poh_type_lookup_code     := po.poh_type_lookup_code; 
            
			-- Almacenar el id a actualizar. 
            IF po.poh_type_lookup_code = 'STANDARD' 
            THEN
               ln_po_id            := po.poh_po_header_id;
            ELSIF po.poh_type_lookup_code = 'BLANKET' 
			THEN 
               ln_po_id            := po.pra_po_release_id;  
            ELSE 
               ln_po_id            := NULL; 
            END IF;             
         END IF; 
         
         fnd_file.put_line(fnd_file.log,' ');        
         fnd_file.put_line(fnd_file.log, 'Linea: '||TO_CHAR(po.pol_po_line_num));
         fnd_file.put_line(fnd_file.log, 'EF: '||NVL(po.pol_oracle_ef, lc_vacio));
         fnd_file.put_line(fnd_file.log, 'CR: '||NVL(po.pol_oracle_cr, lc_vacio));
         fnd_file.put_line(fnd_file.log, 'Codigo de Org: '||po.mtl_inv_organization_code);
         fnd_file.put_line(fnd_file.log, 'No. Articulo: '||NVL(po.msi_item_number, lc_vacio));
         fnd_file.put_line(fnd_file.log, 'Tipo de Uso: '||NVL(po.msi_use_type, lc_vacio));
         fnd_file.put_line(fnd_file.log, 'Clave de Activo Fijo: '||NVL(po.msi_fa_code, lc_vacio));
         fnd_file.put_line(fnd_file.log, 'Descripcion Categoria de Activo Fijo: '||NVL(po.fcb_asset_categ_descr, lc_vacio));
         fnd_file.put_line(fnd_file.log, 'Categoria de Activo Fijo: '||NVL(po.fcb_asset_categ_seg_concat, lc_vacio));              
         fnd_file.put_line(fnd_file.log, 'Clave SAT: '||NVL(po.msi_sat_code, lc_vacio));
         fnd_file.put_line(fnd_file.log, 'Uso de CFDI: '||NVL(po.msi_cfdi_use, lc_vacio));
         
         -- Validar solamente los atributos requeridos para el flujo EBS - SN 
         IF po.pol_oracle_ef IS NULL 
         OR po.pol_oracle_cr IS NULL 
         OR po.msi_item_number IS NULL 
         OR po.msi_use_type IS NULL 
         OR po.msi_fa_code IS NULL 
         OR po.fcb_asset_categ_descr IS NULL    
         OR po.fcb_asset_categ_seg_concat IS NULL           
         OR po.msi_sat_code IS NULL         
         OR po.msi_cfdi_use IS NULL         
         THEN 
            lb_warning := TRUE; 
         END IF; 
         	 
		 -- Otras Validaciones 
		 IF po.msi_inventory_item_flag = 'Y'
		 THEN
		    fnd_file.put_line(fnd_file.log,' *** El articulo esta configurado como inventariable en el modulo de inventarios ***');			    
            lb_warning := TRUE; 			
		 END IF; 
		 
		 IF is_use_item_for_cd_fnc(po.msi_use_type) != 'Y' 
		 THEN 
		    fnd_file.put_line(fnd_file.log,' *** El tipo de uso de articulo no esta configurado para cargos directos en el tipo de mapeo XXFA_SN_PO_OTH_VALIDATE_CD ***');			    
            lb_warning := TRUE; 		  
		 END IF; 
         
         -- Hasta este punto marcar que se encontro la PO
         lb_po_found := TRUE; 
      END LOOP;
      fnd_file.put_line(fnd_file.log,' ');
      
	  -- Actalizar PO/Release 
      IF NOT lb_po_found
      THEN 
         gv_retcode := '1';
         write_errbuf_prc('No se encontro informacion de la PO con Id '||p_po_header_id||'. Despacho Id: '||p_po_release_id||'. En caso de ser un despacho, el parametro Numero de Depacho es requerido.'); 
         RAISE handled_exception;     
         
      ELSE   
         IF lb_warning
         THEN 
            write_errbuf_prc('Se encontraron valores vacios o no validos en atributos requeridos para el flujo de EBS a SN.'); 
            
            update_po_prc (  errbuf                     => gv_errbuf
                           , retcode                    => gv_retcode
                           , p_poh_type_lookup_code     => lc_poh_type_lookup_code
                           , p_po_id                    => ln_po_id
                           , p_validate_flag            => 'N' 
                           ) ;
						   
			write_errbuf_prc(gv_errbuf); 
            
			IF gv_retcode = '0'
			THEN -- Se actualizo correctamente pero sigue como warning. 
			   gv_retcode := '1';	
			END IF;          

            RAISE handled_exception; 			
         ELSE 
            write_errbuf_prc('Todos los atributos requeridos para el flujo de EBS a SN estan completos.'); 
			
            update_po_prc (  errbuf                     => gv_errbuf
                           , retcode                    => gv_retcode
                           , p_poh_type_lookup_code     => lc_poh_type_lookup_code
                           , p_po_id                    => ln_po_id
                           , p_validate_flag            => 'Y' 
                           ) ;
						   
			write_errbuf_prc(gv_errbuf); 
			
			IF gv_retcode != '0'
			THEN 
			   RAISE handled_exception; 
			END IF; 
         END IF;      
      END IF; 

      retcode := '0';
      errbuf  := 'Todos los atributos requeridos para el flujo de EBS a SN estan completos.';    
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');   
      
   EXCEPTION 
      WHEN handled_exception THEN 
         retcode := gv_retcode; 
         errbuf  := gv_errbuf;   
      WHEN OTHERS THEN 
         retcode := '2';
         
         write_errbuf_prc('Error OTHERS xxfa_sn_po_oth_validate_pkg.cd_prc: '||SQLERRM);
         errbuf := gv_errbuf;     
   END cd_prc;    
END xxfa_sn_po_oth_validate_pkg;
/
SHOW ERRORS;