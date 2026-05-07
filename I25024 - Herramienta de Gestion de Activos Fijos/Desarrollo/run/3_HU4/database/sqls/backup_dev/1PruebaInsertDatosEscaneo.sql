

***********************************************
                 PASO 1
***********************************************

    INSERT INTO xxfc_sn_escaneo (
        sn_escaneo_id,
        sn_viaje,
        purchase_order,
        item_number,
        faa_serial_number,
        quantity,
        po_unit_price,
        faa_tag_number
    )
        SELECT
            SN_ESCANEO_ID_SEQ.NEXTVAL,
            NULL sn_viaje,
            RH_HEADER_ID,
            msi_segment1_no_articulo,
            RL_LINE_ID,
            mmt_transaction_quantity, 
            ROUND((MMT_ACTUAL_COST * .98),2),
            --MMT_ACTUAL_COST,
            RL_LINE_ID
        FROM xxinv_material_transactions
        WHERE trunc(mmt_creation_date) = '13-NOV-2024';
		
		 where mmt_transaction_id = 72798373
        
 