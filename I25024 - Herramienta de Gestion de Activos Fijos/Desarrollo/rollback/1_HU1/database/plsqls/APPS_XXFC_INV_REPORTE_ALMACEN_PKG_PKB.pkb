SET DEFINE OFF
PROMPT PACKAGE BODY XXFC_INV_REPORTE_ALMACEN_PKG
create or replace PACKAGE BODY      APPS.XXFC_INV_REPORTE_ALMACEN_PKG AS
/********************************************************************************************
  Modulo      : XXFC_INV_REPORTE_ALMACEN_PKG
  Autor       : Daniel Fernando Vazquez Lujan (Gnarus)
  Fecha       : 17-03-2017
  Descripción : Paquete para el proceso de creacion de reporte de valorizaciones del reporte

  Modificado Por       Fecha              Codigo                 Descripción
--------------------------------------------------------------------------------------------
  Daniel Vazquez     17/03/2017       CHO XXXXXXX      Creacion del paquete para reporte XML XXFC-Reporte de Entradas de Almacén (Valorizaciones)
  J Luis Caldelas CONSISS 	22-AGO-2017 	Upgrade R12.2.4

********************************************************************************************/
   FUNCTION xxfc_inv_beforereport_fnc
      RETURN BOOLEAN
   IS
   BEGIN

      fnd_file.put_line (fnd_file.LOG,'PARAMETROS DEL REPORTE_________________');
      fnd_file.put_line (fnd_file.LOG,'pn_OrgId'||pn_OrgId);
      fnd_file.put_line (fnd_file.LOG,'pn_ProveedorId'||pn_ProveedorId);
      fnd_file.put_line (fnd_file.LOG,'pn_SucursalId'||pn_SucursalId);
      fnd_file.put_line (fnd_file.LOG,'pn_ShipmentId'||pn_ShipmentId);
      fnd_file.put_line (fnd_file.LOG,'pn_Proveedor'||pn_Proveedor);
      fnd_file.put_line (fnd_file.LOG,'pn_Sucursal'||pn_Sucursal);
      fnd_file.put_line (fnd_file.LOG,'pn_ReceiptNum'||pn_ReceiptNum);

      IF pn_ProveedorId IS NULL
      AND pn_ShipmentId IS NULL
      AND pn_SucursalId IS NULL
  	  THEN
  	     pn_ProveedorId := pn_Proveedor;
  	     pn_SucursalId := pn_Sucursal;
  	     pn_ShipmentId := pn_ReceiptNum;
      END IF;

      gv_query := 'SELECT pv.vendor_name provee
                        , pv.segment1 provee_no
                        , rcv.attribute1 invoice_num
                        , pvsa.vendor_site_code site
                        , pha.segment1 po_number
                        , pha.po_header_id header_id
                        , rsh.receipt_num receipt_num
                        , XXFC_INV_REPORTE_ALMACEN_PKG.obtener_release_fnc(rcv.po_release_id
                                             ,pha.po_header_id ) release_num
                        , msi.segment1 articulo
                        , msi.description description
                        , TO_CHAR (TRUNC (rcv.transaction_date), ''DD-MON-YYYY'') fecha
                        , rcv.quantity unids
                        , DECODE( pll.taxable_flag
                                , ''Y''
                                , ( SELECT zl.tax_rate_code
                                    --FROM zx.zx_lines zl --UPG R12.2.4 by J Luis Caldelas CONSISS 22-08-2017
									FROM zx_lines zl
                                    WHERE zl.trx_id = NVL ( pll.po_release_id
                                                          , pll.po_header_id
                                                          )
                                    AND zl.trx_line_id = pll.line_location_id
                                    AND zl.application_id = 201
                                  )
                                , NULL
                                ) tasa
                        , rcv.currency_code divisa_rcv
                        , rcv.currency_conversion_rate tipo_cambio
                        , pha.currency_code divisa
                        , rcv.po_unit_price precio
                        , rcv.po_unit_price * rcv.currency_conversion_rate precio_divisa
                        , ( rcv.quantity*rcv.po_unit_price
                          * rcv.currency_conversion_rate
                          ) Subtotal
                        , DECODE ( pll.taxable_flag
                                 , ''Y''
                                 ,( SELECT DECODE ( zl.tax_rate
                                                  , 0
                                                  , 0
                                                  , (( rcv.quantity * rcv.po_unit_price
                                                     * rcv.currency_conversion_rate
                                                     )* ( zl.tax_rate / 100
                                                        )
                                                    )
                                                  )
                                   --FROM zx.zx_lines zl --UPG R12.2.4 by J Luis Caldelas CONSISS 22-08-2017
								   FROM zx_lines zl
                                   WHERE zl.trx_id = NVL( pll.po_release_id
                                                        , pll.po_header_id)
                                   AND zl.trx_line_id = pll.line_location_id
                                   AND zl.application_id = 201
                                  )
                                 , 0
                                 ) impues
                        , DECODE ( pll.taxable_flag
                                 , ''Y''
                                 , ( SELECT(( rcv.quantity
                                            * rcv.po_unit_price
                                            * rcv.currency_conversion_rate
                                            ) +
                                            (( rcv.quantity
                                             * rcv.po_unit_price
                                             * rcv.currency_conversion_rate
                                             )
                                             * (zl.tax_rate / 100
                                               )
                                            )
                                           )
                                     --FROM zx.zx_lines zl --UPG R12.2.4 by J Luis Caldelas CONSISS 22-08-2017
									 FROM zx_lines zl
                                     WHERE zl.trx_id =NVL ( pll.po_release_id
                                                          , pll.po_header_id
                                                          )
                                     AND zl.trx_line_id = pll.line_location_id
                                     AND zl.application_id = 201
                                   )
                                   ,( rcv.quantity
                                    * rcv.po_unit_price
                                    * rcv.currency_conversion_rate
                                    )
                                 ) total
                   FROM rcv_transactions rcv
                      , po_headers_all pha
                      , po_lines_all pla
                      , rcv_shipment_headers rsh
                      , rcv_shipment_lines rsl
                      , po_vendors pv
                      , po_vendor_sites_all pvsa
                      , mtl_system_items msi
                      , po_line_locations_all pll
                   WHERE pha.po_header_id = rcv.po_header_id
                   AND pla.po_line_id = rcv.po_line_id
                   AND pla.po_header_id = rcv.po_header_id
                   AND pha.po_header_id = pla.po_header_id
                   AND rcv.po_header_id = rsl.po_header_id
                   AND rcv.po_line_id = rsl.po_line_id
                   AND rcv.po_line_location_id = rsl.po_line_location_id
                   AND rsh.shipment_header_id = rcv.shipment_header_id
                   AND rsl.shipment_header_id = rcv.shipment_header_id
                   AND rsl.shipment_line_id = rcv.shipment_line_id
                   AND rsl.shipment_header_id = rcv.shipment_header_id
                   AND rsl.shipment_header_id = rsh.shipment_header_id
                   AND rsl.po_header_id = pla.po_header_id
                   AND rsl.po_line_id = pla.po_line_id
                   AND rcv.vendor_site_id = rsh.vendor_site_id
                   AND rcv.vendor_id = rsh.vendor_id
                   AND pv.vendor_id = rcv.vendor_id
                   AND pvsa.vendor_id = rcv.vendor_id
                   AND pvsa.vendor_site_id = rcv.vendor_site_id
                   AND pv.vendor_id = pvsa.vendor_id
                   AND msi.inventory_item_id = pla.item_id
                   AND pll.po_header_id = pha.po_header_id
                   AND pll.po_line_id = pla.po_line_id
                   AND pll.line_location_id = rcv.po_line_location_id
                   AND rcv.transaction_type = ''RECEIVE''
                   AND pv.vendor_id = NVL ('||pn_ProveedorId||', pv.vendor_id)
                   AND pvsa.vendor_site_id = NVL ('||pn_SucursalId||', pvsa.vendor_site_id)
                   AND rsh.shipment_header_id = '||pn_ShipmentId||'
                   AND msi.organization_id = rcv.organization_id
                   AND NVL (pll.po_release_id, 1) = NVL (rcv.po_release_id, 1)
                   AND rsh.ship_to_org_id = '||pn_OrgId||'
                   AND rcv.organization_id = rsh.ship_to_org_id
                   ORDER BY msi.segment1';

       fnd_file.put_line (fnd_file.LOG,'gv_query = '||gv_query);
       RETURN TRUE;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.LOG,'Error :'||SQLERRM);
         RETURN FALSE;
   END xxfc_inv_beforereport_fnc;

/********************************************************************************************
  Modulo      : xxfc_inv_nombre_reporte_fnc
  Autor       : Daniel Fernando Vazquez Lujan (Gnarus)
  Fecha       : 17-04-2017
  Descripción : Funcion para consultar el nombre del reporte

  Modificado Por       Fecha              Codigo                 Descripción
--------------------------------------------------------------------------------------------
Daniel Vazquez     17/04/2017       CHO XXXXXXX            Creacion de funcion

********************************************************************************************/
   FUNCTION xxfc_inv_nombre_reporte_fnc
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN 'Valorización de Transacción';
   EXCEPTION
      WHEN OTHERS THEN
         RETURN '';
   END xxfc_inv_nombre_reporte_fnc;

/********************************************************************************************
  Modulo      : xxfc_inv_nombre_proveedor_fnc
  Autor       : Daniel Fernando Vazquez Lujan (Gnarus)
  Fecha       : 17-04-2017
  Descripción : Funcion para consultar el nombre del proveedor

  Modificado Por       Fecha              Codigo                 Descripción
--------------------------------------------------------------------------------------------
Daniel Vazquez     17/04/2017       CHO XXXXXXX            Creacion de funcion

********************************************************************************************/
   FUNCTION xxfc_inv_nombre_proveedor_fnc
      RETURN VARCHAR2
   IS
   BEGIN
      SELECT vendor_name
      INTO gv_Descripcion
      FROM po_vendors
      WHERE vendor_id = pn_ProveedorId;

     RETURN(gv_Descripcion);
   EXCEPTION
      WHEN others THEN
        gv_Descripcion := '';
        fnd_file.put_line (fnd_file.LOG,'Error :'||SQLERRM);
        RETURN(gv_Descripcion);
   END xxfc_inv_nombre_proveedor_fnc;

   FUNCTION xxfc_inv_afterreport_fnc
      RETURN BOOLEAN
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG,'FIN REPORTE');
      RETURN TRUE;
   END xxfc_inv_afterreport_fnc;

   FUNCTION obtener_release_fnc(p_ReleaseId IN NUMBER
                              , p_HeaderId  IN NUMBER)
      RETURN NUMBER IS
/********************************************************************************************
  Modulo      : apps.obtener_release_fnc
  Autor       : Daniel Vazquez(GNarus)
  Fecha       : 19-Abr-2017
  Descripción : Funcion para obtener el número de release

  Modificado Por       Fecha              Codigo                 Descripción
--------------------------------------------------------------------------------------------
  Daniel Vazquez     19/04/2017       CHO XXXXX           Creacion de funcion

********************************************************************************************/

ln_ReleaseNum   NUMBER;
BEGIN
  SELECT release_num
    INTO ln_ReleaseNum
    FROM po_releases_all
   WHERE po_release_id = p_ReleaseId
     AND po_header_id  = p_HeaderId;
   RETURN (ln_ReleaseNum );
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN(NULL);
   WHEN OTHERS THEN
      RETURN(NULL);
END;



END XXFC_INV_REPORTE_ALMACEN_PKG;
/
SHOW ERRORS;