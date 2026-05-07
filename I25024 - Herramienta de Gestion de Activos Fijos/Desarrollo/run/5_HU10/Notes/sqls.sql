SELECT  wt.trip_id AS wst_trip_id
      , wt.name AS wst_trip_name 
      , wdd.source_line_id ool_line_id        
      , ooh.header_id AS ooh_header_id 
      , ooh.order_number AS ooh_order_number
      , wdd.shipped_quantity
      , wnd.confirm_date
      , wdd.*
      , wt.*      
FROM    apps.oe_order_headers_all ooh
      , apps.wsh_delivery_details wdd
      , apps.wsh_new_deliveries wnd
      , apps.wsh_delivery_assignments wda
      , apps.wsh_trips wt
      , apps.wsh_delivery_legs wdl
      , apps.wsh_trip_stops wds_pick     
      , apps.wsh_trip_stops wds_drop   
      , apps.mtl_system_items_b msi 
WHERE  1 = 1
AND    ooh.header_id               = wdd.source_header_id (+)
AND    wda.delivery_detail_id(+)   = wdd.delivery_detail_id
AND    wda.delivery_id             = wnd.delivery_id(+)
AND    wdl.delivery_id(+)          = wnd.delivery_id  
AND    wt.trip_id                  = wds_pick.trip_id
AND    wds_pick.stop_id(+)         = wdl.pick_up_stop_id
AND    wt.trip_id                  = wds_drop.trip_id
AND    wds_drop.stop_id(+)         = wdl.drop_off_stop_id     
AND    msi.inventory_item_id       = wdd.inventory_item_id 
AND    msi.organization_id         = wdd.organization_id
--AND    wt.name                     = '415036'
--and wdd.source_line_id  = 33610
--Valia la organizacion de inventario
--and wt.status_Code != 'CL'
and  wdd.released_status  = 'C'
and   wnd.confirm_date is null
AND   EXISTS 
      (
      SELECT 1
      FROM   apps.fnd_flex_values_vl ffv
           , apps.fnd_flex_value_sets fvs
      WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
      AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
      AND    ffv.enabled_flag = 'Y'
      AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
      AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
      AND    ffv.flex_value = TO_CHAR(wdd.organization_id)
      ) 
-- Valida el uso del articulo 
AND EXISTS 
    (
    SELECT 1
    FROM   apps.xxfc_mapeos_varios xmv
    WHERE  xmv.tipo_mapeo = 'XXFA_SN_INSERT_DATA_DETAILS'
    AND    xmv.entrada    LIKE 'USE_ITEM%'
    AND    xmv.salida1    = msi.attribute1 
    AND    xmv.estado     = 'A'
    AND    ( xmv.fecha_inicial < SYSDATE OR xmv.fecha_inicial IS NULL )
    AND    ( xmv.fecha_final > SYSDATE OR xmv.fecha_final IS NULL )
    )        
ORDER BY 3;  


select *
from  apps.wsh_trips
where status_code = 'CL'



select *
from  apps.wsh_trips






SELECT  1001
      , wt.name AS wst_trip_name 
      , msi.description AS msi_item_description
      , msi.segment1 AS msi_item_number
      , wdd.shipped_quantity
      , ooh.order_number AS ooh_order_number
      , ooh.header_id AS ooh_header_id
      , wdd.source_line_id ool_line_id        
      , 'Y'     
FROM    apps.oe_order_headers_all ooh
      , apps.wsh_delivery_details wdd
      , apps.wsh_new_deliveries wnd
      , apps.wsh_delivery_assignments wda
      , apps.wsh_trips wt
      , apps.wsh_delivery_legs wdl
      , apps.wsh_trip_stops wds_pick     
      , apps.wsh_trip_stops wds_drop   
      , apps.mtl_system_items_b msi 
WHERE  1 = 1
AND    ooh.header_id               = wdd.source_header_id (+)
AND    wda.delivery_detail_id(+)   = wdd.delivery_detail_id
AND    wda.delivery_id             = wnd.delivery_id(+)
AND    wdl.delivery_id(+)          = wnd.delivery_id  
AND    wt.trip_id                  = wds_pick.trip_id
AND    wds_pick.stop_id(+)         = wdl.pick_up_stop_id
AND    wt.trip_id                  = wds_drop.trip_id
AND    wds_drop.stop_id(+)         = wdl.drop_off_stop_id     
AND    msi.inventory_item_id       = wdd.inventory_item_id 
AND    msi.organization_id         = wdd.organization_id
AND    wt.name                     = '995016'
--and wdd.source_line_id  = 33610
--Valia la organizacion de inventario
--and wt.status_Code != 'CL'
--and  wdd.released_status  = 'D'
--and   wnd.confirm_date is null
AND   EXISTS 
      (
      SELECT 1
      FROM   apps.fnd_flex_values_vl ffv
           , apps.fnd_flex_value_sets fvs
      WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
      AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
      AND    ffv.enabled_flag = 'Y'
      AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
      AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
      AND    ffv.flex_value = TO_CHAR(wdd.organization_id)
      )        
ORDER BY 3;  


SELECT  wt.trip_id  
      , wt.name AS wst_trip_name 
      , msi.segment1 AS msi_item_number
      , msi.description AS msi_item_description
      , wdd.shipped_quantity AS wdd_shipped_quantity
      , ooh.header_id AS ooh_header_id
      , ooh.order_number AS ooh_order_number
      , wdd.source_line_id ool_line_id        
      , CASE
	       WHEN wt.status_code!= 'CL' 
		   THEN 
		      'Y'     
	       ELSE 
              'N'
        END ship_confirm_flag
      , wnd.confirm_date AS wnd_confirm_date	
      , wt.status_code AS wt_status_code	
      , wdd.released_status AS wdd_released_status	  
FROM    apps.oe_order_headers_all ooh
      , apps.wsh_delivery_details wdd
      , apps.wsh_new_deliveries wnd
      , apps.wsh_delivery_assignments wda
      , apps.wsh_trips wt
      , apps.wsh_delivery_legs wdl
      , apps.wsh_trip_stops wds_pick     
      , apps.wsh_trip_stops wds_drop   
      , apps.mtl_system_items_b msi 
WHERE  1 = 1
AND    ooh.header_id               = wdd.source_header_id (+)
AND    wda.delivery_detail_id(+)   = wdd.delivery_detail_id
AND    wda.delivery_id             = wnd.delivery_id(+)
AND    wdl.delivery_id(+)          = wnd.delivery_id  
AND    wt.trip_id                  = wds_pick.trip_id
AND    wds_pick.stop_id(+)         = wdl.pick_up_stop_id
AND    wt.trip_id                  = wds_drop.trip_id
AND    wds_drop.stop_id(+)         = wdl.drop_off_stop_id     
AND    msi.inventory_item_id       = wdd.inventory_item_id 
AND    msi.organization_id         = wdd.organization_id
AND    wt.name                     = '995016'
--and wdd.source_line_id  = 33610
--Valia la organizacion de inventario
--and wt.status_Code != 'CL'
--and  wdd.released_status  = 'D'
--and   wnd.confirm_date is null
AND   EXISTS 
      (
      SELECT 1
      FROM   apps.fnd_flex_values_vl ffv
           , apps.fnd_flex_value_sets fvs
      WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
      AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
      AND    ffv.enabled_flag = 'Y'
      AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
      AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
      AND    ffv.flex_value = TO_CHAR(wdd.organization_id)
      )        
;



xxfc.xxfa_sn_trips (
sn_trip_detail_id          	   NUMBER DEFAULT XXFC.xxfa_sn_trip_details_s.NEXTVAL NOT NULL,
sn_trip_id               	   NUMBER         NOT NULL,
wst_trip_id                    NUMBER         NOT NULL,
wst_trip_name	               VARCHAR2(30), 
msi_item_number                VARCHAR2(40)   NOT NULL,
msi_item_description           VARCHAR2(240),
wdd_shipped_quantity           NUMBER, 
ooh_header_id                  NUMBER, 
ooh_order_number               NUMBER,
ool_line_id                    NUMBER,
ship_confirm_flag              VARCHAR2(1),
wnd_confirm_date               DATE, 
wt_status_code                 VARCHAR2(2),
wdd_released_status            VARCHAR2(1),
creation_date                  DATE DEFAULT SYSDATE,
created_by                     NUMBER DEFAULT -1,
last_update_date               DATE DEFAULT SYSDATE,
last_updated_by                NUMBER DEFAULT -1,
last_update_login              NUMBER DEFAULT -1


DECLARE
   ln_trip_name       wsh_trips.name%TYPE  := '995016'; 
   
   TYPE lrec_trips IS RECORD (
                               wst_trip_id               wsh_trips.trip_id%TYPE      
                             , wst_trip_name	         wsh_trips.name%TYPE      
                             , msi_item_number           mtl_system_items_b.segment1%TYPE      
                             , msi_item_description      mtl_system_items_b.description%TYPE      
                             , wdd_shipped_quantity      wsh_delivery_details.shipped_quantity%TYPE      
                             , ooh_header_id             oe_order_headers_all.header_id%TYPE      
                             , ooh_order_number          oe_order_headers_all.order_number%TYPE      
                             , ool_line_id               wsh_delivery_details.source_line_id%TYPE      
                             , ship_confirm_flag         xxfa_sn_trips.ship_confirm_flag%TYPE  
							 , wnd_delivery_id           wsh_new_deliveries.delivery_id%TYPE 
                             , wnd_confirm_date          wsh_new_deliveries.confirm_date%TYPE 
                             , wt_status_code            wsh_trips.status_code%TYPE 
                             , wdd_delivery_detail_id    wsh_delivery_details.delivery_detail_id%TYPE 
                             , wdd_organization_id       wsh_delivery_details.organization_id%TYPE  
                             , wdd_released_status       wsh_delivery_details.released_status%TYPE    							 
                             ); 
   TYPE ltab_trips IS TABLE OF lrec_trips INDEX BY PLS_INTEGER;

   larr_wsh_trips       ltab_trips;
   larr_sn_trips        ltab_trips;
   
   lb_insert_sn_trip    BOOLEAN := FALSE; 
   
   ln_sn_trip_id        NUMBER; 
   
   CURSOR c_wsh_trip( p_trip_name IN VARCHAR2
                    ) 
   IS  
      SELECT  wt.trip_id              AS wst_trip_id
            , wt.name                 AS wst_trip_name 
            , msi.segment1            AS msi_item_number
            , msi.description         AS msi_item_description
            , wdd.shipped_quantity    AS wdd_shipped_quantity
            , ooh.header_id           AS ooh_header_id
            , ooh.order_number        AS ooh_order_number
            , wdd.source_line_id      AS ool_line_id        
            , CASE
      	       WHEN wt.status_code!= 'CL' 
      		   THEN 
      		      'Y'     
      	       ELSE 
                    'N'
              END ship_confirm_flag
            , wnd.delivery_id         AS wnd_delivery_id  
            , wnd.confirm_date        AS wnd_confirm_date	
            , wt.status_code          AS wt_status_code	
            , wdd.delivery_detail_id  AS wdd_delivery_detail_id
            , wdd.organization_id     AS wdd_organization_id
            , wdd.released_status     AS wdd_released_status	
      FROM    oe_order_headers_all ooh
            , wsh_delivery_details wdd
            , wsh_new_deliveries wnd
            , wsh_delivery_assignments wda
            , wsh_trips wt
            , wsh_delivery_legs wdl
            , wsh_trip_stops wds_pick     
            , wsh_trip_stops wds_drop   
            , mtl_system_items_b msi 
      WHERE  1 = 1
      AND    ooh.header_id               = wdd.source_header_id (+)
      AND    wda.delivery_detail_id(+)   = wdd.delivery_detail_id
      AND    wda.delivery_id             = wnd.delivery_id(+)
      AND    wdl.delivery_id(+)          = wnd.delivery_id  
      AND    wt.trip_id                  = wds_pick.trip_id
      AND    wds_pick.stop_id(+)         = wdl.pick_up_stop_id
      AND    wt.trip_id                  = wds_drop.trip_id
      AND    wds_drop.stop_id(+)         = wdl.drop_off_stop_id     
      AND    msi.inventory_item_id       = wdd.inventory_item_id 
      AND    msi.organization_id         = wdd.organization_id
      AND    wt.name                     = p_trip_name
      ;

   CURSOR c_sn_trip( p_trip_name IN VARCHAR2
                    ) 
   IS 
      SELECT  wst_trip_id
            , wst_trip_name 
            , msi_item_number
            , msi_item_description
            , wdd_shipped_quantity
            , ooh_header_id
            , ooh_order_number
            , ool_line_id        
            , ship_confirm_flag
            , wnd_delivery_id  
            , wnd_confirm_date	
            , wt_status_code	
            , wdd_delivery_detail_id
            , wdd_organization_id
            , wdd_released_status	
      FROM    xxfa_sn_trips
	  WHERE   wst_trip_name = p_trip_name
	  AND     sn_trip_id    = (SELECT MAX(sn_trip_id)
	                           FROM   xxfa_sn_trips
							   WHERE  wst_trip_name = p_trip_name
                               )
      ;
   
   -- Funcion para comparar arreglos y saber si hay cambios que reportar a SN 
   FUNCTION arrays_equal(p_arr_wsh IN ltab_trips
                       , p_arr_sn  IN ltab_trips
					     ) 
   RETURN BOOLEAN IS
       idx PLS_INTEGER;
   BEGIN
   
      -- Checar si las cantidades no son iguales
      IF p_arr_wsh.COUNT != p_arr_sn.COUNT 
	  THEN
         RETURN FALSE;
      END IF;
   
      -- Revisar los arreglos a partir de la llave, primer arreglo 
      idx := p_arr_wsh.FIRST;
      WHILE k IS NOT NULL 
	  LOOP
         -- Revisa si el idx existe en el segundo arreglo 
         IF NOT p_arr_sn.EXISTS(k) 
		 THEN
            RETURN FALSE;
         END IF;
   
         -- Compara valores (solo los que se mandan a SN) 
         IF NVL(p_arr_wsh(idx).wst_trip_id, '0')             != NVL(p_arr_sn(idx).wst_trip_id, '0') 
		 OR NVL(p_arr_wsh(idx).wst_trip_name, 'NULL')        != NVL(p_arr_sn(idx).wst_trip_name, 'NULL')
         OR NVL(p_arr_wsh(idx).msi_item_number, 'NULL')      != NVL(p_arr_sn(idx).msi_item_number, 'NULL')
         OR NVL(p_arr_wsh(idx).msi_item_description, 'NULL') != NVL(p_arr_sn(idx).msi_item_description, 'NULL')
         OR NVL(p_arr_wsh(idx).wdd_shipped_quantity, '0')    != NVL(p_arr_sn(idx).wdd_shipped_quantity, '0')
         OR NVL(p_arr_wsh(idx).ooh_header_id, '0')           != NVL(p_arr_sn(idx).ooh_header_id, '0')   		 
         OR NVL(p_arr_wsh(idx).ooh_order_number, 'NULL')     != NVL(p_arr_sn(idx).ooh_order_number, 'NULL')  
         OR NVL(p_arr_wsh(idx).ool_line_id, 'NULL')          != NVL(p_arr_sn(idx).ool_line_id, 'NULL')  
         OR NVL(p_arr_wsh(idx).ship_confirm_flag, 'NULL')    != NVL(p_arr_sn(idx).ship_confirm_flag, 'NULL')  		 
		 THEN
            RETURN FALSE;
         END IF;
   
         idx := p_arr_sn.NEXT(idx);
      END LOOP;


      -- Revisar los arreglos a partir de la llave, segundo arreglo 
      idx := p_arr_sn.FIRST;
      WHILE k IS NOT NULL 
	  LOOP
         -- Revisa si el idx existe en el primer arreglo 
         IF NOT p_arr_wsh.EXISTS(k) 
		 THEN
            RETURN FALSE;
         END IF;
   
         idx := p_arr_sn.NEXT(idx);
      END LOOP;

   
      RETURN TRUE; -- Si los arrelos son iguales 
   EXCEPTION
      WHEN OTHERS THEN 
         dbms_output.put_line('arrays_equal: '||SQLERRM);   
         RETURN FALSE;		 
   END arrays_equal;
   
BEGIN

   -- Limpiar arreglos 
   larr_wsh_trips.DELETE;
   larr_sn_trips.DELETE;

   -- Cargar arreglo para wsh 
   FOR wsh IN c_wsh_trip(p_trip_name => ln_trip_name
                        )
   LOOP
      larr_wsh_trips(wsh.wdd_delivery_detail_id).wst_trip_id            := wsh.wst_trip_id;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).wst_trip_name          := wsh.wst_trip_name;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).msi_item_number        := wsh.msi_item_number;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).msi_item_description   := wsh.msi_item_description;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_shipped_quantity   := wsh.wdd_shipped_quantity;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).ooh_header_id          := wsh.ooh_header_id;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).ooh_order_number       := wsh.ooh_order_number;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).ool_line_id            := wsh.ool_line_id;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).ship_confirm_flag      := wsh.ship_confirm_flag;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).wnd_delivery_id        := wsh.wnd_delivery_id;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).wnd_confirm_date       := wsh.wnd_confirm_date;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).wt_status_code         := wsh.wt_status_code;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_delivery_detail_id := wsh.wdd_delivery_detail_id;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_organization_id    := wsh.wdd_organization_id;
	  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_released_status    := wsh.wdd_released_status;
   END LOOP; 
   

   dbms_output.put_line('larr_wsh_trips.COUNT: '||larr_wsh_trips.COUNT);


   -- Cargar arreglo para sn 
   FOR sn IN c_wsh_trip(p_trip_name => ln_trip_name
                        )
   LOOP
      larr_sn_trips(sn.wdd_delivery_detail_id).wst_trip_id            := sn.wst_trip_id;
	  larr_sn_trips(sn.wdd_delivery_detail_id).wst_trip_name          := sn.wst_trip_name;
	  larr_sn_trips(sn.wdd_delivery_detail_id).msi_item_number        := sn.msi_item_number;
	  larr_sn_trips(sn.wdd_delivery_detail_id).msi_item_description   := sn.msi_item_description;
	  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_shipped_quantity   := sn.wdd_shipped_quantity;
	  larr_sn_trips(sn.wdd_delivery_detail_id).ooh_header_id          := sn.ooh_header_id;
	  larr_sn_trips(sn.wdd_delivery_detail_id).ooh_order_number       := sn.ooh_order_number;
	  larr_sn_trips(sn.wdd_delivery_detail_id).ool_line_id            := sn.ool_line_id;
	  larr_sn_trips(sn.wdd_delivery_detail_id).ship_confirm_flag      := sn.ship_confirm_flag;
	  larr_sn_trips(sn.wdd_delivery_detail_id).wnd_delivery_id        := sn.wnd_delivery_id;
	  larr_sn_trips(sn.wdd_delivery_detail_id).wnd_confirm_date       := sn.wnd_confirm_date;
	  larr_sn_trips(sn.wdd_delivery_detail_id).wt_status_code         := sn.wt_status_code;
	  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_delivery_detail_id := sn.wdd_delivery_detail_id;
	  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_organization_id    := sn.wdd_organization_id;
	  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_released_status    := sn.wdd_released_status;
   END LOOP; 
   

   dbms_output.put_line('larr_sn_trips.COUNT: '||larr_wsh_trips.COUNT);


   -- Comparar los arreglos para saber si hay cambios que enviar a SN 
   IF NOT arrays_equal( p_arr_wsh => larr_wsh_trips
                      , p_arr_sn  => larr_sn_trips
				      ) 
   THEN 
      dbms_output.put_line('arreglos diferentes');
	  
	  
      SELECT  xxfc.xxfa_sn_trips_s.nextval
	  INTO    ln_sn_trip_id
	  FROM    dual
	  ;
      
	  INSERT INTO xxfc.xxfa_sn_trips( sn_trip_id             
                                    , wst_trip_id            
                                    , wst_trip_name	       
                                    , msi_item_number        
                                    , msi_item_description   
                                    , wdd_shipped_quantity   
                                    , ooh_header_id          
                                    , ooh_order_number       
                                    , ool_line_id            
                                    , ship_confirm_flag      
                                    , wnd_delivery_id        
                                    , wnd_confirm_date       
                                    , wt_status_code         
                                    , wdd_delivery_detail_id 
                                    , wdd_organization_id    
                                    , wdd_released_status    
                                    , creation_date          
                                    , created_by             
                                    , last_update_date       
                                    , last_updated_by        
                                    , last_update_login  
                                     ) 
      SELECT  ln_sn_trip_id									 
            , wt.trip_id              AS wst_trip_id
            , wt.name                 AS wst_trip_name 
            , msi.segment1            AS msi_item_number
            , msi.description         AS msi_item_description
            , wdd.shipped_quantity    AS wdd_shipped_quantity
            , ooh.header_id           AS ooh_header_id
            , ooh.order_number        AS ooh_order_number
            , wdd.source_line_id      AS ool_line_id        
            , CASE
      	       WHEN wt.status_code!= 'CL' 
      		   THEN 
      		      'Y'     
      	       ELSE 
                    'N'
              END ship_confirm_flag
            , wnd.delivery_id         AS wnd_delivery_id  
            , wnd.confirm_date        AS wnd_confirm_date	
            , wt.status_code          AS wt_status_code	
            , wdd.delivery_detail_id  AS wdd_delivery_detail_id
            , wdd.organization_id     AS wdd_organization_id
            , wdd.released_status     AS wdd_released_status	
			, SYSDATE
			, FND_PROFILE.value('USER_ID')
			, SYSDATE
			, FND_PROFILE.value('USER_ID')
			, FND_PROFILE.value('LOGIN_ID')
      FROM    oe_order_headers_all ooh
            , wsh_delivery_details wdd
            , wsh_new_deliveries wnd
            , wsh_delivery_assignments wda
            , wsh_trips wt
            , wsh_delivery_legs wdl
            , wsh_trip_stops wds_pick     
            , wsh_trip_stops wds_drop   
            , mtl_system_items_b msi 
      WHERE  1 = 1
      AND    ooh.header_id               = wdd.source_header_id (+)
      AND    wda.delivery_detail_id(+)   = wdd.delivery_detail_id
      AND    wda.delivery_id             = wnd.delivery_id(+)
      AND    wdl.delivery_id(+)          = wnd.delivery_id  
      AND    wt.trip_id                  = wds_pick.trip_id
      AND    wds_pick.stop_id(+)         = wdl.pick_up_stop_id
      AND    wt.trip_id                  = wds_drop.trip_id
      AND    wds_drop.stop_id(+)         = wdl.drop_off_stop_id     
      AND    msi.inventory_item_id       = wdd.inventory_item_id 
      AND    msi.organization_id         = wdd.organization_id
      AND    wt.name                     = ln_trip_name
      ;  
	  
	  COMMIT;
   END IF;

EXCEPTION 
   WHEN OTHERS THEN 
      dbms_output.put_line('ERROR: '||SQLERRM);
END;






DECLARE
    -- Define an associative array type
    TYPE t_assoc_array IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;

    -- Two associative arrays to compare
    arr1 t_assoc_array;
    arr2 t_assoc_array;

    -- Function to compare two associative arrays
    FUNCTION arrays_equal(a1 t_assoc_array, a2 t_assoc_array) RETURN BOOLEAN IS
        k PLS_INTEGER;
    BEGIN
        -- First check if counts match
        IF a1.COUNT != a2.COUNT THEN
            RETURN FALSE;
        END IF;

        -- Iterate through all keys in first array
        k := a1.FIRST;
        WHILE k IS NOT NULL LOOP
            -- Check if key exists in second array
            IF NOT a2.EXISTS(k) THEN
                RETURN FALSE;
            END IF;

            -- Compare values (NULL-safe)
            IF NVL(a1(k), '¤NULL¤') != NVL(a2(k), '¤NULL¤') THEN
                RETURN FALSE;
            END IF;

            k := a1.NEXT(k);
        END LOOP;

        RETURN TRUE; -- All keys and values match
    END arrays_equal;

BEGIN
    -- Populate first array
    arr1(1) := 'Apple';
    arr1(2) := 'Banana';
    arr1(3) := 'Cherry';

    -- Populate second array
    arr2(1) := 'Apple';
    arr2(2) := 'Banana';
    arr2(3) := 'Cherry';

    -- Compare arrays
    IF arrays_equal(arr1, arr2) THEN
        DBMS_OUTPUT.PUT_LINE('Arrays are equal.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Arrays are NOT equal.');
    END IF;
END;
/