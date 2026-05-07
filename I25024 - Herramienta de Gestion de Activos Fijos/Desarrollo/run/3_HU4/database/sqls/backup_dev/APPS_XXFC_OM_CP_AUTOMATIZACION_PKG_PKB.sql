CREATE OR REPLACE PACKAGE BODY XXFC_OM_CP_AUTOMATIZACION_PKG
IS
   /***************************************************************************************
   # Modulo        : XXFC_OM_CP_AUTOMATIZACION_PKG
   # Autor         : Samanta Solis
   # Versión       : 1.0
   # Fecha         : 28-Agosto-2023
   # Descripción   : Ejecuta el concurrente "XXFC-Carta Porte Almacen AF – Tienda" recibiendo el numero de viaje 
   #                 y "XXFC-Carta Porte Recolección Salidas Virtuales"
   # Ejecutado Por : 
   #
   # Ejecuciones   : 
   #
   # Modificado Por         Fecha         Descripcion
   # -------------------------------------------------------------------------------------
   # Samanta Solis          28/Ago/2023   CHG0037801 Creacion de paquete
   # Samanta Solis          12/Ago/2024   CHG0046621 1) Se agrega parametro para validar estatus de la ejecucion 
                                                     del concurrente Generación de Lista de Selección
                                                     2) Se elimina validacion de despacho del pedido
   ***************************************************************************************/

   /********************************************************************************************
   Modulo      : inicio_prc
   Autor       : Samanta Solis
   Fecha       : 28-Agosto-2023
   Descripcion : Ejecuta el concurrente XXFC-Carta Porte Almacen AF – Tienda 
   
   Modificado Por       Fecha          Descripcion
   --------------------------------------------------------------------------------------------
   Samanta Solis      28/Ago/2023    CHG0037801 Creacion de procedimiento
   Samanta Solis      12/Ago/2024    CHG0046621 1) Se agrega parametro para validar estatus de la ejecucion 
                                                del concurrente Generación de Lista de Selección
                                                2) Se elimina validacion de despacho del pedido     
   ********************************************************************************************/
   PROCEDURE inicio_prc ( xv_Errbuf   OUT VARCHAR2
                        , xv_Retcode  OUT VARCHAR2
                        , pv_no_viaje IN  VARCHAR2
                        , pn_org_id   IN  NUMBER
                         )
    IS
    -- Verifica si existe concurrente en ejecución
    CURSOR lcur_ReqRunning IS
         SELECT MAX(request_id)
         FROM   apps.fnd_concurrent_requests     fcr,
                apps.fnd_concurrent_programs_tl  fcpt,
                apps.fnd_user fu
         WHERE  fcr.concurrent_program_id = fcpt.concurrent_program_id
         AND    fcr.requested_by = fu.user_id
         AND    fcpt.language = 'ESA'
         AND    fcpt.user_concurrent_program_name LIKE 'Generación de Lista de Selección'
         AND    fcr.actual_start_date  < SYSDATE
         --AND    round((( sysdate - fcr.actual_start_date ) * 24 * 30 ),2) < 5
         AND    fu.user_id = fnd_profile.value('USER_ID');

    CURSOR lcur_PedidosReq IS
        SELECT  DISTINCT ooh.order_number   AS orden   
              , ooh.cust_po_number AS requisicion   
              , ooh.attribute4 AS embarque
              , (SELECT o.order_number FROM apps.oe_order_headers_all o 
                 WHERE  o.cust_po_number = ooh.cust_po_number 
                 AND    o.attribute4 = emb.embarque_req) AS orden_rec
        FROM    apps.oe_order_headers_all ooh
              , apps.oe_order_lines_all ool
              , apps.po_requisition_lines_all pla -- Obtener el CR de Plaza Destino
              , apps.wsh_delivery_details wdd
              , apps.wsh_new_deliveries wnd
              , apps.wsh_delivery_assignments wda
              , apps.wsh_trips wt
              , apps.wsh_delivery_legs wdl
              , apps.wsh_trip_stops wds_pick
              , apps.xxfc_cp_cat_ubicaciones u
              , apps.wsh_trip_stops ts
              , apps.wms_dock_appointments_b vc
              , (SELECT ffv.flex_value embarque_req,ffv.flex_value_meaning embarque
                 FROM   apps.fnd_flex_value_sets fvs, 
                        apps.fnd_flex_values_vl ffv
                 WHERE  fvs.flex_value_set_name  = 'XXFC_OM_AUTO_CCP_EMBARQUE'
                 AND    fvs.flex_value_set_id   = ffv.flex_value_set_id
                 AND    ffv.enabled_flag = 'Y'
                 AND    ffv.description = 'CCP_RECOLECCION') emb
         WHERE  1 = 1
         AND    ooh.header_id = ool.header_id
         AND    ool.attribute1 = pla.requisition_line_id
         AND    ooh.header_id = wdd.source_header_id(+)
         AND    wda.delivery_detail_id(+) = wdd.delivery_detail_id
         AND    wda.delivery_id = wnd.delivery_id(+)
         AND    ool.line_id = wdd.source_line_id
         AND    wdl.delivery_id(+) = wnd.delivery_id
         AND    wt.trip_id = wds_pick.trip_id
         AND    wds_pick.stop_id(+) = wdl.pick_up_stop_id
         AND    wt.name = pv_no_viaje
         AND    u.cr_plaza(+) = pla.attribute2
         AND    u.clave_cr(+) = ool.attribute3 
         AND    ts.trip_id =  wt.name 
         AND    ts.stop_id = vc.trip_stop
         AND    ooh.attribute4  = emb.embarque ; 

    lv_recoleccion    VARCHAR2(20);
    lv_fase           VARCHAR2(20);
    lv_estatus        VARCHAR2(20);
    lv_continua       VARCHAR2(20);
    ln_req_id         NUMBER;
    lv_PhaseOut       VARCHAR2(50);
    lv_StatusOut      VARCHAR2(50);
    lv_DevPhaseOut    VARCHAR2(50);
    lv_DevStatusOut   VARCHAR2(50);
    lv_MessageOut     VARCHAR2(100);
    ln_ReqRunning     NUMBER;
    lb_CallStatus     BOOLEAN;
    le_exception      EXCEPTION;
    lv_ubicacion      VARCHAR2(50);
    ln_horas          NUMBER;
    ln_minutos        NUMBER;
    ln_dias           NUMBER;
    ln_distancia      NUMBER;
    lv_trans          VARCHAR2(50);
    lv_correo         VARCHAR2(200);
    lv_correo_default VARCHAR2(200);
    lv_funcion        VARCHAR2(100);
    lv_dist_default	  VARCHAR2(50);
    ln_orden          NUMBER;
    lv_requisicion    VARCHAR2(50);
    lv_embarque       VARCHAR2(50);
    ln_orden_rec      NUMBER;
    ln_ReqActual      NUMBER;

   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 'pn_org_id   :'||pn_org_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 'pv_no_viaje :'||pv_no_viaje);

      lv_funcion := obtiene_juego_valores_fnc ('XXFC_OM_AUTO_CCP','MINUTOS');

      IF lv_funcion IS NULL THEN
         ln_minutos := 3;
      ELSE 
         ln_minutos := TO_NUMBER(TRIM(lv_funcion));
         FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                         'MINUTOS ['||ln_minutos||'] juego de valores XXFC_OM_AUTO_CCP');
      END IF;

      ln_ReqActual:= fnd_global.conc_request_id;
 
      FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                      'Request Actual  ['||ln_ReqActual||']');

      BEGIN

         SELECT parent_request_id
         INTO   ln_ReqRunning
         FROM   apps.fnd_concurrent_requests     fcr,
                apps.fnd_concurrent_programs_tl  fcpt
         WHERE  fcr.concurrent_program_id = fcpt.concurrent_program_id
         AND    fcpt.language = 'ESA'
         AND    fcr.request_id = ln_ReqActual;

      EXCEPTION
         WHEN OTHERS THEN
            ln_ReqRunning := NULL;
      END;

      --Inicio CHG0046621
      IF ln_ReqRunning = NULL 
      OR ln_ReqRunning = -1
      THEN

         lv_funcion := obtiene_juego_valores_fnc ('XXFC_OM_AUTO_CCP_ESTATUS','NULO');
         FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                         'NULO ['||lv_funcion||'] juego de valores XXFC_OM_AUTO_CCP_ESTATUS');

      END IF;

      --IF ln_ReqRunning IS NOT NULL
      --AND ln_ReqRunning != -1
      IF (ln_ReqRunning IS NOT NULL
      AND ln_ReqRunning != -1 )
      OR (lv_funcion = 'NULO')
      THEN
         IF lv_funcion = 'NULO' 
         THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                            'No se requiere validar ejecucion de la solicitud "Generación de Lista de Selección"');
            lv_continua := 'OK';
         ELSE
	  --Fin CHG0046621 
            FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                            'Existe solicitud ['||ln_ReqRunning||'] del concurrente "Generación de Lista de Selección" ');

            lb_CallStatus := APPS.FND_CONCURRENT.WAIT_FOR_REQUEST( request_id => ln_ReqRunning,
                                                                   INTERVAL   => 5,
                                                                   max_wait   => ln_minutos * 60,
                                                                   phase      => lv_PhaseOut,
                                                                   status     => lv_StatusOut,
                                                                   dev_phase  => lv_DevPhaseOut,
                                                                   dev_status => lv_DevStatusOut,
                                                                   message    => lv_MessageOut);

            FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                            'Solicitud ['||ln_ReqRunning||'] '||
                                            'Fase ['||lv_DevPhaseOut||'] '||
                                            'Estado ['||lv_DevStatusOut||']');
            --Inicio CHG0046621
            lv_funcion := obtiene_juego_valores_fnc ('XXFC_OM_AUTO_CCP_ESTATUS',NVL(lv_DevPhaseOut,'NULO'));

            --IF NOT (lv_DevPhaseOut = 'COMPLETE' AND lv_DevStatusOut = 'NORMAL')
            IF lv_funcion IS NULL
            THEN
            --Fin CHG0046621

               FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                               'La ejecucion de la solicitud ['||ln_ReqRunning||'] "Generación de Lista de Selección" Fallo');
               lv_continua := 'ERROR';
               RAISE le_exception;
            ELSE

               FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                               'La ejecucion de la solicitud ['||ln_ReqRunning||'] "Generación de Lista de Selección" termino con estatus '
                                               --Inicio CHG0046621
                                               ||lv_DevPhaseOut||'/'||lv_DevStatusOut);
                                               --Fin CHG0046621
               lv_continua := 'OK';
            END IF; 
			
         --Inicio CHG0046621			
         END IF;
         --Fin CHG0046621
      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                         'No se pudo obtener la solicitud de "Generación de Lista de Selección"');
         FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                         'Ejecute manualmente el XML CCP');
         lv_continua := 'ERROR';
         RAISE le_exception;
      END IF;

      IF lv_continua = 'OK'
      THEN
         ---obtener transportista, correo y pedido

         BEGIN

            SELECT  MAX((SELECT ffv.description
                         FROM   apps.fnd_flex_value_sets fvs, 
                                apps.fnd_flex_values_vl ffv
                         WHERE  fvs.flex_value_set_name  = 'XXFC_OM_AUTO_CCP_DISTANCIA'
                         AND    fvs.flex_value_set_id   = ffv.flex_value_set_id
                         AND    ffv.enabled_flag = 'Y'
                         AND    ffv.flex_value = u.estado))AS distancia
                  , c.carrier_name AS transportista
                  , cs.attribute1 AS correo
            INTO    ln_distancia
                  , lv_trans
                  , lv_correo
            FROM    apps.oe_order_headers_all ooh
                  , apps.oe_order_lines_all ool
                  , apps.po_requisition_lines_all pla -- Obtener el CR de Plaza Destino
                  , apps.wsh_delivery_details wdd
                  , apps.wsh_new_deliveries wnd
                  , apps.wsh_delivery_assignments wda
                  , apps.wsh_trips wt
                  , apps.wsh_delivery_legs wdl
                  , apps.wsh_trip_stops wds_pick
                  , apps.xxfc_cp_cat_ubicaciones u
                  , apps.wsh_trip_stops ts
                  , apps.wms_dock_appointments_b vc
                  , apps.wsh_carriers_v c
                  , apps.wsh_carrier_services cs
             WHERE  1 = 1
             AND    ooh.header_id = ool.header_id
             AND    ool.attribute1 = pla.requisition_line_id
             AND    ooh.header_id = wdd.source_header_id(+)
             AND    wda.delivery_detail_id(+) = wdd.delivery_detail_id
             AND    wda.delivery_id = wnd.delivery_id(+)
             AND    ool.line_id = wdd.source_line_id
             AND    wdl.delivery_id(+) = wnd.delivery_id
             AND    wt.trip_id = wds_pick.trip_id
             AND    wds_pick.stop_id(+) = wdl.pick_up_stop_id
             AND    wt.name = pv_no_viaje
             AND    u.cr_plaza(+) = pla.attribute2
             AND    u.clave_cr(+) = ool.attribute3 
             AND    ts.trip_id =  wt.name 
             AND    ts.stop_id = vc.trip_stop
             AND    vc.carrier_code =c.freight_code
             AND    c.carrier_id = cs.carrier_id
             AND    ooh.attribute4  IN (SELECT ffv.flex_value_meaning
                                        FROM   apps.fnd_flex_value_sets fvs, 
                                               apps.fnd_flex_values_vl ffv
                                        WHERE  fvs.flex_value_set_name  = 'XXFC_OM_AUTO_CCP_EMBARQUE'
                                        AND    fvs.flex_value_set_id   = ffv.flex_value_set_id
                                        AND    ffv.enabled_flag = 'Y'
                                        AND    ffv.description = 'CCP_ALMACEN')
             GROUP BY  c.carrier_name, cs.attribute1;
         EXCEPTION 
            WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                               'Error: al obtener distancia, transportista y su correo del viaje ['||pv_no_viaje||'] '||SQLERRM);
               FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                               'Validar asignacion de muelle del viaje ['||pv_no_viaje||'] '||SQLERRM);
               RAISE le_exception;
        END;
		
        FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                         'Transportista ['||lv_trans||'] '|| 
                                         'Correo transportista ['||lv_correo||']' 
                                         );

        lv_funcion := obtiene_juego_valores_fnc ('XXFC_OM_AUTO_CCP','UBICACION');

        IF lv_funcion IS NULL THEN
           lv_ubicacion := NULL;
           RAISE le_exception;
        ELSE
           lv_ubicacion := lv_funcion;
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                        'UBICACION ['||lv_ubicacion||'] juego de valores XXFC_OM_AUTO_CCP');
  
        lv_funcion := obtiene_juego_valores_fnc ('XXFC_OM_AUTO_CCP','DIAS');
  
        IF lv_funcion IS NULL THEN
           ln_dias := 10;
        ELSE 
           ln_dias := TO_NUMBER(lv_funcion);
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                        'DIAS ['||ln_dias||'] juego de valores XXFC_OM_AUTO_CCP');
  
        lv_funcion := obtiene_juego_valores_fnc ('XXFC_OM_AUTO_CCP','HORAS');
  
        IF lv_funcion IS NULL THEN
           ln_horas := 1;
        ELSE 
           ln_horas := TO_NUMBER(TRIM(lv_funcion));
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                        'HORAS ['||ln_horas||'] juego de valores XXFC_OM_AUTO_CCP');

        IF lv_correo IS NULL 
        THEN
           lv_funcion := obtiene_juego_valores_fnc ('XXFC_OM_AUTO_CCP','CORREO');

           IF lv_funcion IS NULL 
           THEN
              lv_correo := NULL;
              RAISE le_exception;
           ELSE
              lv_correo := lv_funcion;
           END IF;

           FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                           'CORREO ['||lv_correo||'] existe en el juego de valores XXFC_OM_AUTO_CCP');
        END IF;

        IF ln_distancia IS NULL 
        THEN
           lv_funcion := obtiene_juego_valores_fnc ('XXFC_OM_AUTO_CCP','DISTANCIA');

           IF lv_funcion IS NULL 
           THEN
              ln_distancia := NULL;
              RAISE le_exception;
           ELSE
              ln_distancia := TO_NUMBER(TRIM(lv_funcion));
           END IF;  
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                        'DISTANCIA ['||ln_distancia||'] juego de valores XXFC_OM_AUTO_CCP');

        ---ejecuta concurrente XXFC-Carta Porte Almacen AF – Tienda

        ejecuta_concurrente_prc( pv_application => 'XXFC'
                               , pv_program     => 'XXFC_CP_ALMACEN_AF'
                               , pv_argument1   => NULL--PV_SO_NO_PEDIDO
                               , pv_argument2   => pv_no_viaje--PV_WSH_NO_VIAJE
                               , pv_argument3   => NULL--PV_CR_PLAZA_O
                               , pv_argument4   => lv_ubicacion--PV_CAT_UBICACION_O
                               , pv_argument5   => TO_CHAR(SYSDATE + ln_horas/24, 'RRRR/MM/DD HH24:MI:SS')--PV_FECHAHORA_SALIDA
                               , pv_argument6   => TO_CHAR(SYSDATE + ln_dias, 'RRRR/MM/DD HH24:MI:SS') --PV_FECHAHORA_LLEGADA
                               , pv_argument7   => ln_distancia--PV_DISTANCIA_RECORRIDA
                               , pv_argument8   => NULL--PV_CARTA_PORTE_ID
                               , pv_argument9   => NULL--PV_CP_SOBRE_ESCRIBIR_FLAG
                               , pv_argument10  => lv_correo--PV_DIR_CORREOS
                               , pv_argument11  => lv_trans--PV_TRANSPORTISTA
                               , pn_user_id     => FND_GLOBAL.USER_ID
                               , pn_resp_id     => FND_GLOBAL.RESP_ID
                               , pn_app_id      => FND_GLOBAL.RESP_APPL_ID
                               , pn_req_id      => ln_req_id
                               );
        IF ln_req_id != 0 
        THEN
           lb_CallStatus := APPS.FND_CONCURRENT.WAIT_FOR_REQUEST( request_id => ln_req_id,
                                                                  INTERVAL   => 5,
                                                                  max_wait   => ln_minutos * 60,
                                                                  phase      => lv_PhaseOut,
                                                                  status     => lv_StatusOut,
                                                                  dev_phase  => lv_DevPhaseOut,
                                                                  dev_status => lv_DevStatusOut,
                                                                  message    => lv_MessageOut);

           FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                           'Solicitud ['||ln_req_id||'] '||
                                           'Fase ['||lv_DevPhaseOut||'] '||
                                           'Estado ['||lv_DevStatusOut||']');

           IF NOT (lv_DevPhaseOut = 'COMPLETE' AND lv_DevStatusOut = 'NORMAL')
           THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                               'La ejecucion de la solicitud ['||ln_req_id||'] "XXFC-Carta Porte Almacen AF – Tienda" Fallo');
               lv_continua := 'ERROR';
               RAISE le_exception;
           ELSE
               FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                               'La ejecucion de la solicitud ['||ln_req_id||'] "XXFC-Carta Porte Almacen AF – Tienda" termino con exito');
               lv_continua := 'OK';
           END IF;

           IF lv_continua = 'OK'
           THEN
              FOR c IN lcur_PedidosReq LOOP

                 ln_orden       := c.orden;
                 lv_requisicion := c.requisicion;
                 lv_embarque    := c.embarque;
                 ln_orden_rec   := c.orden_rec;
			   
                 --Los embarques se deberán enviar de la siguiente manera:
                 --El embarque 1 deberá de ser enviado con el embarque 4
                 --El embarque 2 se va solo
                 --El embarque 3 deberá de ser enviado con el embarque 5

                 ---Ejecuta concurrente XXFC-Carta Porte Recolección Salidas Virtuales

                 ejecuta_concurrente_prc( pv_application => 'XXFC'
                                        , pv_program     => 'XXFC_CP_SALIDAS_VIRTUALES'
                                        , pv_argument1   => ln_orden_rec--PV_SO_NO_PEDIDO
                                        , pv_argument2   => NULL--PV_CR_PLAZA_O
                                        , pv_argument3   => lv_ubicacion--PV_CAT_UBICACION_O
                                        , pv_argument4   => TO_CHAR(SYSDATE + ln_horas/24, 'RRRR/MM/DD HH24:MI:SS')--PV_FECHAHORA_SALIDA
                                        , pv_argument5   => TO_CHAR(SYSDATE + ln_dias, 'RRRR/MM/DD HH24:MI:SS') --PV_FECHAHORA_LLEGADA
                                        , pv_argument6   => ln_distancia--PV_DISTANCIA_RECORRIDA
                                        , pv_argument7   => NULL--PV_CARTA_PORTE_ID
                                        , pv_argument8   => NULL--PV_CP_SOBRE_ESCRIBIR_FLAG
                                        , pv_argument9   => lv_correo--PV_DIR_CORREOS
                                        , pv_argument10  => lv_trans--PV_TRANSPORTISTA
                                        , pv_argument11  => NULL
                                        , pn_user_id     => FND_GLOBAL.USER_ID
                                        , pn_resp_id     => FND_GLOBAL.RESP_ID
                                        , pn_app_id      => FND_GLOBAL.RESP_APPL_ID
                                        , pn_req_id      => ln_req_id
                                        );

                 IF ln_req_id != 0 
                 THEN

                    lb_CallStatus := APPS.FND_CONCURRENT.WAIT_FOR_REQUEST( request_id => ln_req_id,
                                                                           INTERVAL   => 5,
                                                                           max_wait   => ln_minutos * 60,
                                                                           phase      => lv_PhaseOut,
                                                                           status     => lv_StatusOut,
                                                                           dev_phase  => lv_DevPhaseOut,
                                                                           dev_status => lv_DevStatusOut,
                                                                           message    => lv_MessageOut);
              
                    FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                                    'Solicitud ['||ln_req_id||'] '||
                                                    'Fase ['||lv_DevPhaseOut||'] '||
                                                    'Estado ['||lv_DevStatusOut||']');
              
                    IF NOT (lv_DevPhaseOut = 'COMPLETE' AND lv_DevStatusOut = 'NORMAL')
                    THEN
                       FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                                       'La ejecucion de la solicitud ['||ln_req_id||'] " XXFC-Carta Porte Recolección Salidas Virtuales" Fallo');
                       lv_continua := 'ERROR';
                       RAISE le_exception;
                    ELSE
                       FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                                       'La ejecucion de la solicitud ['||ln_req_id||'] "XXFC-Carta Porte Recolección Salidas Virtuales" termino con exito');
                    END IF;
                 ELSE 
                    FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                                    'Error al ejecutar concurrente "XXFC-Carta Porte Recolección Salidas Virtuales"'); 
                 END IF;--ln_req_id != 0
              END LOOP;
           END IF; --llv_continua = 'OK'
        ELSE
           FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                           'Error al ejecutar concurrente "XXFC-Carta Porte Almacen AF – Tienda"'); 
        END IF;--ln_req_id != 0
      END IF;--lv_continua = 'OK'
   EXCEPTION
      WHEN le_exception THEN
         xv_Retcode := 1;
      WHEN OTHERS THEN
         xv_Retcode := 2;
         xv_Errbuf  := SQLERRM;
         FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 'Error: inicio_prc '|| SQLERRM); 
   END inicio_prc;

   /********************************************************************************************
   Modulo      : ejecuta_concurrente_prc
   Autor       : Samanta Solis
   Fecha       : 28-Agosto-2023
   Descripcion : Ejecuta el concurrente XXFC-Carta Porte Automatizacion
   
   Modificado Por       Fecha          Descripcion
   --------------------------------------------------------------------------------------------
   Samanta Solis      28/Ago/2023    CHG0037801 Creacion de procedimiento
   ********************************************************************************************/
   PROCEDURE ejecuta_concurrente_prc( pv_application IN  VARCHAR2
                                    , pv_program     IN  VARCHAR2
                                    , pv_argument1   IN  VARCHAR2
                                    , pv_argument2   IN  VARCHAR2
                                    , pv_argument3   IN  VARCHAR2
                                    , pv_argument4   IN  VARCHAR2
                                    , pv_argument5   IN  VARCHAR2
                                    , pv_argument6   IN  VARCHAR2
                                    , pv_argument7   IN  VARCHAR2
                                    , pv_argument8   IN  VARCHAR2
                                    , pv_argument9   IN  VARCHAR2
                                    , pv_argument10  IN  VARCHAR2
                                    , pv_argument11  IN  VARCHAR2
                                    , pn_user_id     IN  NUMBER
                                    , pn_resp_id     IN  NUMBER
                                    , pn_app_id      IN  NUMBER
                                    , pn_req_id      OUT NUMBER)
   IS
   ln_req_id      NUMBER;
   lv_err_code    VARCHAR2(100);
   lv_err_msg     VARCHAR2(100);
   lv_concurrente VARCHAR2(300);
   ln_resp_id     NUMBER;
   ln_app_id      NUMBER;
   BEGIN
   
      IF pn_resp_id IS  NULL 
      THEN 
         ln_resp_id := FND_GLOBAL.RESP_ID;
      ELSE
         ln_resp_id := pn_resp_id;
      END IF;
      
      IF pn_app_id IS NULL 
      THEN 
         ln_app_id := FND_GLOBAL.RESP_APPL_ID;
      ELSE
         ln_app_id := pn_app_id;
      END IF;
       
      fnd_global.apps_initialize(pn_user_id, ln_resp_id,ln_app_id);

      FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                      'fnd_global.apps_initialize('||pn_user_id||','||pn_resp_id||','||pn_app_id||')');
     

      BEGIN
         SELECT user_concurrent_program_name
         INTO   lv_concurrente
         FROM   apps.fnd_concurrent_programs_vl 
         WHERE  concurrent_program_name = pv_program;
      EXCEPTION
         WHEN OTHERS THEN
            lv_concurrente := NULL;
      END;

      FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '||
                                      'Ejecuta concurrente "'||lv_concurrente||'"');
      
      IF pv_argument4 IS NULL 
      THEN
         ln_req_id := apps.fnd_request.submit_request (  application  =>  pv_application
                                                       , program      =>  pv_program
                                                       , description  =>  NULL
                                                       , start_time   =>  NULL
                                                       , sub_request  =>  FALSE
                                                       , argument1    =>  pv_argument1
                                                       , argument2    =>  pv_argument2
                                                       );
      ELSIF pv_argument11 IS NULL 
      THEN 
         ln_req_id := apps.fnd_request.submit_request (  application  =>  pv_application
                                                       , program      =>  pv_program
                                                       , description  =>  NULL
                                                       , start_time   =>  NULL
                                                       , sub_request  =>  FALSE
                                                       , argument1    =>  pv_argument1
                                                       , argument2    =>  pv_argument2
                                                       , argument3    =>  pv_argument3
                                                       , argument4    =>  pv_argument4
                                                       , argument5    =>  pv_argument5
                                                       , argument6    =>  pv_argument6
                                                       , argument7    =>  pv_argument7
                                                       , argument8    =>  pv_argument8
                                                       , argument9    =>  pv_argument9
                                                       , argument10   =>  pv_argument10
                                                       );
      ELSE
         ln_req_id := apps.fnd_request.submit_request (  application  =>  pv_application
                                                       , program      =>  pv_program
                                                       , description  =>  NULL
                                                       , start_time   =>  NULL
                                                       , sub_request  =>  FALSE
                                                       , argument1    =>  pv_argument1
                                                       , argument2    =>  pv_argument2
                                                       , argument3    =>  pv_argument3
                                                       , argument4    =>  pv_argument4
                                                       , argument5    =>  pv_argument5
                                                       , argument6    =>  pv_argument6
                                                       , argument7    =>  pv_argument7
                                                       , argument8    =>  pv_argument8
                                                       , argument9    =>  pv_argument9
                                                       , argument10   =>  pv_argument10
                                                       , argument11   =>  pv_argument11
                                                       );
       END IF;

       COMMIT;
       pn_req_id := ln_req_id;

   EXCEPTION
      WHEN OTHERS THEN
         ln_req_id:=0;
         FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 'Error: ejecuta_concurrente_prc '|| SQLERRM); 
   END ejecuta_concurrente_prc;   

   /********************************************************************************************
   Modulo      : obtiene_juego_valores_fnc
   Autor       : Samanta Solis
   Fecha       : 28-Agosto-2023
   Descripcion : Obtiene juego de valores
   
   Modificado Por       Fecha          Descripcion
   --------------------------------------------------------------------------------------------
   Samanta Solis      28/Ago/2023    CHG0037801 Creacion de funcion
   ********************************************************************************************/
   FUNCTION obtiene_juego_valores_fnc( pv_set_name    IN  VARCHAR2
                                     , pv_flex_value  IN  VARCHAR2
                                     )
   RETURN VARCHAR2
   IS
   lv_descripcion VARCHAR2(100);
   BEGIN
   
      SELECT ffv.description
      INTO   lv_descripcion
      FROM   apps.fnd_flex_value_sets fvs, 
             apps.fnd_flex_values_vl ffv
      WHERE  fvs.flex_value_set_name = pv_set_name
      AND    fvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffv.enabled_flag = 'Y'
      AND    ffv.flex_value = pv_flex_value;
   
      RETURN lv_descripcion;

   EXCEPTION 
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '|| 
                                         'Error: obtiene_juego_valores_fnc ['||pv_set_name||'|'||pv_flex_value||'] '||SQLERRM);
         RETURN NULL;
   END;
 
END XXFC_OM_CP_AUTOMATIZACION_PKG;
/
SHOW ERRORS;