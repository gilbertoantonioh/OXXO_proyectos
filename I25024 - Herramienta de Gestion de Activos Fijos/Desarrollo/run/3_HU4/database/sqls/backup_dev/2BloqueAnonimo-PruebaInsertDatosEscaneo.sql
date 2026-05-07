--***********************************************
--                 PASO 2
--***********************************************

DECLARE
    ls_viaje VARCHAR2(30);
    CURSOR cur_registros IS
    SELECT
        scan.*
    FROM
        XXFC.xxfc_sn_escaneo scan
    FOR UPDATE OF scan.sn_viaje;

BEGIN
    FOR k IN cur_registros LOOP
        ls_viaje := NULL;
        SELECT DISTINCT
            wts.trip_id
        INTO ls_viaje
        FROM
            apps.wsh_delivery_legs wdl,
            apps.wsh_trip_stops    wts
        WHERE
                1 = 1
            AND wdl.pick_up_stop_id = wts.stop_id
            AND wdl.delivery_id IN (
                SELECT DISTINCT
                    wda.delivery_id
                FROM
                    apps.wsh_delivery_assignments wda, apps.wsh_delivery_details     wdd
                WHERE
                        1 = 1
                    AND wda.delivery_detail_id = wdd.delivery_detail_id
                    AND wdd.source_header_number = k.purchase_order--ooh.order_number
                    AND wdd.source_line_id = k.FAA_SERIAL_NUMBER--ool.line_id
            );

        dbms_output.put_line('Viaje: ' || ls_viaje);
        UPDATE xxfc_sn_escaneo
        SET
            sn_viaje = ls_viaje
        WHERE
            CURRENT OF cur_registros;

    END LOOP;
    
    COMMIT;
END;