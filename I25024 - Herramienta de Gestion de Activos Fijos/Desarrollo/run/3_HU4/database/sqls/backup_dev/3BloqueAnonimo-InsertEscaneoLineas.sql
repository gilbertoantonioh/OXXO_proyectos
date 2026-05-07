--*************************************
--          PASO 3
--*************************************

DECLARE
    ls_viaje VARCHAR2(30);
    CURSOR cur_registros IS
    SELECT
        scan.*
    FROM
        xxfc_sn_escaneo scan
    WHERE
        abs(quantity) > 1;

BEGIN
    INSERT INTO xxfc_sn_escaneo_lineas (
        sn_escaneo_linea_id,
        sn_viaje,
        item_number,
        faa_serial_number,
        po_unit_price,
        faa_tag_number,
        sts_header_id,
        sts_line_id,
        sn_escaneo_id
    )
        SELECT
            sn_escaneo_id_seq.NEXTVAL,
            sn_viaje,
            item_number,
            faa_serial_number,
            po_unit_price,
            faa_tag_number,
            NULL sts_header_id,
            NULL sts_line_id,
            sn_escaneo_id
        FROM
            xxfc_sn_escaneo
        WHERE
            abs(quantity) = 1;

    FOR k IN cur_registros LOOP
        FOR i IN 1..abs(k.quantity) LOOP
            INSERT INTO xxfc_sn_escaneo_lineas (
                sn_escaneo_linea_id,
                sn_viaje,
                item_number,
                faa_serial_number,
                po_unit_price,
                faa_tag_number,
                sts_header_id,
                sts_line_id,
                sn_escaneo_id
            ) VALUES (
                sn_escaneo_id_seq.NEXTVAL,
                k.sn_viaje,
                k.item_number,
                k.faa_serial_number,
                k.po_unit_price,
                k.faa_tag_number,
                NULL,
                NULL,
                k.sn_escaneo_id
            );

        END LOOP;
    END LOOP;

END;