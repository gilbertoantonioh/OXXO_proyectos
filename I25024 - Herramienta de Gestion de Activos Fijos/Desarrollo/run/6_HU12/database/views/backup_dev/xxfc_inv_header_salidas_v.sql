SELECT distinct   --mmt.transaction_source_id move_order,CO51967670
            ooh.order_number move_order,
            mmt.transaction_set_id transaccion,
             /*Inicio CO51967670 */
           -- mtr.transaction_header_id header_id, prh.segment1 no_requisicion,
              mmt.transaction_set_id header_id
            , prh.segment1 no_requisicion
            ,
            /*Fin CO51967670*/
            prh.attribute1 si_legacy, mmt.transaction_date txn_date,
            mmt.organization_id organization_id, prh.attribute2 cr_plaza,
            prh.attribute3 cr_tienda, mmt.created_by usuario,
            mmt.attribute6, mmt.attribute7, mmt.attribute8, mmt.attribute9
       FROM mtl_material_transactions mmt,
       /*Inicio CO51967670 */
           -- mtl_txn_request_lines mtr,
            --apps.oe_order_lines_all ool,
            apps.oe_order_headers_all ooh,
       /*Fin CO51967670 */
          --  po_requisition_lines_all prl,
            po_requisition_headers_all prh
      /*Inicio CO51967670 */
     -- WHERE mmt.transaction_type_id = 63
     --   AND mmt.transaction_action_id = 1
     --   AND mmt.transaction_source_type_id = 4
       WHERE mmt.transaction_type_id = 33
       AND   mmt.transaction_action_id = 1
       AND   mmt.transaction_source_type_id = 2
     --   AND mtr.inventory_item_id = mmt.inventory_item_id
     --   AND mtr.attribute1 = prl.requisition_line_id
     --   AND mmt.trx_source_line_id = mtr.line_id
     --  AND   ool.inventory_item_id = mmt.inventory_item_id
       AND   mmt.transaction_reference=ooh.header_id
       AND   mmt.transaction_date >= ooh.booked_date
     --  AND   ooh.header_id = ool.header_id
       --AND   ool.attribute1 = prl.requisition_line_id
       AND   ooh.attribute2 = prh.requisition_header_id
        /*Fin CO51967670 */
    --  AND   prh.requisition_header_id = prl.requisition_header_id