create or replace PACKAGE      xxinv_item_fixed_asset_web_pkg
IS
/***
Object Name : xxinv_item_fixed_asset_web_pkg
Type        : Package
Purpose     : Prepare the information for the interface LEGACY, grupo total, kits and others
Pre-reqs : None.
Parameters :
    errbuf IN OUT VARCHAR2
   ,retcode IN OUT VARCHAR2
   ,p_org_id IN NUMBER
   Notes :
           **** COMPILE in apps     ******
   revisions:
   ver        date         author                  description
   ---------  -----------  ----------------------  ------------------------------------
   0          Undefined    MASCOM people           1. created this Package
   1          15.Nov.2006  Leobardo Mtz.           1. Include de org_id as parameter in funcion CHECK_ITEM_ATTRIBUTE, cus is part of the primary
                                                      key in mtl_system_items table.
                                                   2. Obtain the CR at requisition level
   2          16.Nov.2006  Leobardo Mtz.           1. Some transactions are set at gl_batch_id, then included some requisition.
                                                      To prevent this, we included the requisition number in summary cursor.
   3          17.Nov.2006  Leobardo Mtz.           1. The items must be line by line, in kits.
   4          22.Nov.2006  Leobardo Mtz.           2. Implement better logic to include item by item in asset
   5          27.Nov.2006  Leobardo Mtz.           1. Implement the cr's distribution in grupo_total
   6          05.Dic.2006  Leobardo Mtz.           1. Include decimals in cost of kits
   7          06.Dic.2006  Leobardo Mtz.           1. 06.Dic.2006, LmC OTConsulting the Quantity must be 1 and the cost the total by group
                                                      in grupototal. Change required by Irma
   8          11.Dic.2006  Leobardo Mtz.           1. Change the cursor to summarized the kits.
   9          19.Dic.2006  Leobardo Mtz.           1. Implement the detail of group
   10         04.Ene.2007  Leobardo Mtz.           1. Implement the detail of return to store
   11         08.Ene.2007  Leobardo Mtz.           1. Filter the detail of group to R.23 and V.29 item type
   12         09.Ene.2007  Leobardo Mtz.           1. Apply the filter of expense in detail group
   13         11.Ene.2007  Leobardo Mtz.           1. Change the logic of return to store, must be group by account segment4
   14         16.Ene.2007  Leobardo Mtz.           1. Change the way to get the return to store using the table xxinv_issue_fixed_asset_web
   15         23.Ene.2007  Leobardo Mtz.           1. Extend the values for attribute2, include: 'G.04','G.06','G.12','G.13','G.14','G.15'
   16         29.Ene.2007  Leobardo Mtz.           1. The cost of the kit must be the cost of transaction istead of average cost
   17         29.Ene.2007  Leobardo Mtz.           1. Exclude the value 'G.04' from the values for attribute2 set
   18         07.Feb.2007  Leobardo Mtz.           1. Get the header id of the move order from de requisition id (attribute2 in the move order)
   19         14.Mar.2007  Leobardo Mtz.           1. Add the filter by line_id or line_number in retur to store
                                                   2. Change the name of file in return to store
   20         14.Mar.2007  Leobardo Mtz.           1. Exclude the child items that are alone from the kits in cursor c_dev
   21          16.July.2008  Bhavya Sharma            Modified the package as a part of R12 Upgrade process
   22         11.Nov.2013   Laura De Santiago      CHO 51413405. 1. Se elimina las validaciones para determinar
                                                   si es plaza Legacy u Oracle.
                                                   2. Al encontrar un error en categoria no inserte activo y envie correo a usuarios
***/
   PROCEDURE main (errbuf OUT VARCHAR2, retcode OUT VARCHAR2, p_date IN DATE, p_org_id IN NUMBER);

-- 15.Nov.2006, LmC OTConsulting. To check the item attribute must be with the org_id in mtl_system_items, So Add parameter p_org_id
   FUNCTION check_item_attribute (p_org_id NUMBER, p_item_id IN NUMBER, p_move_id IN NUMBER, p_line_num IN NUMBER)
      RETURN VARCHAR2;


   /* ***
      Purpouse: In Oracle Fixed Assets GoLive
      Validate every Item if it must be interfaced to LegacyFA or OracleFA

      Paulino Reyes OTConsulting   December 2009
   *** */
   FUNCTION ofa_valid_iface_code (
      p_cursor_code      IN   VARCHAR2 DEFAULT NULL
    , p_legacy_ef        IN   VARCHAR2 DEFAULT NULL
    , p_interface_type   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2;

   /* ***
      Purpouse: In Oracle Fixed Assets GoLive
      After Inventory to Legacy FA interface ends, This procedure
      must be executed to validate and send all items identified in the
      Interface_Type column to FA_MASS_ADDITIONS table to upload Assets.

      Paulino Reyes OTConsulting   December 2009
   *** */
   PROCEDURE fa_mass_additions_iface (p_date IN DATE, p_retcode IN OUT VARCHAR2);

   PROCEDURE devoluciones (p_date IN DATE,p_org_id IN NUMBER, p_retcode IN OUT VARCHAR2);


END;
/