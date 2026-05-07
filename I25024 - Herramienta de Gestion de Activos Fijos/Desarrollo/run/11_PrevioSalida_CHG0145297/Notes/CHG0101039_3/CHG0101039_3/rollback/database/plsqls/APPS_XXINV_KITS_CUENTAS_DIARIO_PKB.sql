create or replace PACKAGE BODY      XXINV_KITS_CUENTAS_DIARIO IS
--=================================================================================================
--* Modulo        : XXINV_KITS_CUENTAS_DIARIO
--* Ejecutado por : Concurrente XXINV: Creacion de transacciones contables en resumen
--
--* Modificado por         Fecha       Descripcion
--* -------------------------------------------------------------------------------------------------
--  Gabriel Padilla Caro	22/Nov/2018 ChO 52008259 Correcci?e la cuenta gasto de Salidas de Almacen
-- Juan Pedro Carrera     4/Marzo/2021 CHO 52073456  Pregunta por predecesor, lo cual indica que es
--                                                   tienda operando anteriormente
-- J Luis Caldelas        13-Mayo-2021  CHO 52079043 Upgrade R12.2.4
-- Ismael Guerrero        17-Junio-2022  CHO 52104689 Validacion CR predecesor tiene mas de 3 meses
--=================================================================================================

PROCEDURE main(errbuf         OUT VARCHAR2,
                retcode        OUT VARCHAR2,
                p_org_id       IN  NUMBER,
                p_fecha        IN  VARCHAR2)
 IS

-- Obtiene los articulos padre y su cantidad total para saber cuantos kits de c/u va a integrar
CURSOR CALCULA_KIT_ITEM_SALDO (P_FECHA IN DATE, P_ORG_ID NUMBER) IS
SELECT MSI_ATTRIBUTE4_PARENT_MAND PARENT_MAND, AF_ORACLE_EF ORACLE_EF, REQL_ATTRIBUTE3_CR ORACLE_CR ,
--       xmt.MSI_SEGMENT1_NO_ARTICULO, xmt.MSI_ATTRIBUTE6_PARENT_HIJOS,
       SUM(MMT_TRANSACTION_QUANTITY*-1) CANTIDAD
FROM   apps.XXINV_MATERIAL_TRX_TEMP xmt --FROM   xxfc.XXINV_MATERIAL_TRX_TEMP xmt --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
WHERE  NVL(MSI_ATTRIBUTE8_MAE_YN,'N') = 'Y'
AND    trunc(MMT_CREATION_DATE) = trunc(P_FECHA)
AND    MMT_ORGANIZATION_ID = P_ORG_ID
GROUP BY MSI_ATTRIBUTE4_PARENT_MAND, AF_ORACLE_EF, REQL_ATTRIBUTE3_CR;
--         xmt.MSI_SEGMENT1_NO_ARTICULO, xmt.MSI_ATTRIBUTE6_PARENT_HIJOS;

CURSOR INSERTA_MANDATORIOS_KITS (P_FECHA  IN DATE, P_ORG_ID IN NUMBER) IS
SELECT MMT_TRANSACTION_ID,
       MMT_INVENTORY_ITEM_ID, MSI_ATTRIBUTE4_PARENT_MAND,REQL_ATTRIBUTE2_CRSUP,REQL_ATTRIBUTE3_CR,
       AF_ORACLE_EF, RH_HEADER_ID, MMT_TRANSACTION_QUANTITY*-1 MMT_TRANSACTION_QUANTITY,
       REQH_REQUISITION_HEADER_ID,
       RL_ATTRIBUTE1_REQ_LINE_ID,MMT_CREATION_DATE,MSI_SEGMENT1_NO_ARTICULO,RL_LINE_ID,
       MSI_ATTRIBUTE8_MAE_YN
FROM   apps.XXINV_MATERIAL_TRX_TEMP --xxfc.XXINV_MATERIAL_TRX_TEMP --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
WHERE  MMT_ORGANIZATION_ID = P_ORG_ID
AND    MSI_ATTRIBUTE7_MAE_TIPO = 'KIT'
AND    NVL(MSI_ATTRIBUTE8_MAE_YN,'N') = 'Y'
AND    TRUNC(MMT_CREATION_DATE) = TRUNC(P_FECHA)
ORDER BY AF_ORACLE_EF,REQL_ATTRIBUTE3_CR,MSI_ATTRIBUTE4_PARENT_MAND, MSI_SEGMENT1_NO_ARTICULO, MMT_TRANSACTION_QUANTITY;
--AND ATTRIBUTE12 is null

CURSOR INSERTA_HIJOS_TRX (P_FECHA  IN DATE, P_ORG_ID IN NUMBER) IS
SELECT  *
FROM    XXINV_MATERIAL_TRX_TEMP  --xxfc.XXINV_MATERIAL_TRX_TEMP  --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
WHERE   MMT_ORGANIZATION_ID = P_ORG_ID
AND     MSI_ATTRIBUTE7_MAE_TIPO = 'KIT'
AND     NVL(MSI_ATTRIBUTE8_MAE_YN,'N') != 'Y'
AND     TRUNC(MMT_CREATION_DATE) = TRUNC(P_FECHA)
AND      AF_STATUS_KITS IS NULL
ORDER BY AF_ORACLE_EF,REQL_ATTRIBUTE3_CR,MSI_SEGMENT1_NO_ARTICULO, MMT_TRANSACTION_QUANTITY
FOR UPDATE OF AF_TIPO_USO_CONVERTIDO;
--AND ATTRIBUTE12 is null

CURSOR  INSERTA_HIJOS_KITS (P_FECHA IN DATE) IS
SELECT   *
FROM     XXINV_KIT_SALDO_DIARIO --XXFC.XXINV_KIT_SALDO_DIARIO --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
WHERE    saldo_padre != surtido
AND      trunc(FECHA) =TRUNC(P_FECHA)
ORDER BY oracle_ef,oracle_cr,item_no
FOR UPDATE OF surtido;

CURSOR ASIGNA_CUENTA (P_FECHA  IN DATE, P_ORG_ID IN NUMBER) IS
SELECT  *
FROM    XXINV_MATERIAL_TRX_TEMP XMT --xxfc.XXINV_MATERIAL_TRX_TEMP XMT --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
WHERE   MMT_ORGANIZATION_ID = P_ORG_ID
AND     TRUNC(MMT_CREATION_DATE) = TRUNC(P_FECHA)
ORDER BY AF_ORACLE_EF,REQL_ATTRIBUTE3_CR,xmt.MSI_ATTRIBUTE2_MAE_ACTIVO ,AF_TIPO_USO_CONVERTIDO DESC
FOR UPDATE OF XMT.MMT_DISTRIBUTION_ACCOUNT_ID ;

CURSOR ASIGNA_CIA (P_FECHA  IN DATE, P_ORG_ID IN NUMBER) IS
SELECT  *
FROM    XXINV_MATERIAL_TRX_TEMP XMT --xxfc.XXINV_MATERIAL_TRX_TEMP XMT --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
WHERE   MMT_ORGANIZATION_ID = P_ORG_ID
AND     TRUNC(MMT_CREATION_DATE) = TRUNC(P_FECHA)
ORDER BY AF_ORACLE_EF,REQL_ATTRIBUTE3_CR,MSI_SEGMENT1_NO_ARTICULO
FOR UPDATE OF AF_ORACLE_CIA;

CURSOR c_code_combination_id (p_segment1 IN VARCHAR2,p_segment2 IN VARCHAR2,
       p_segment3 IN VARCHAR2,
       p_segment4 IN VARCHAR2) IS
SELECT code_combination_id
FROM gl_code_combinations
WHERE segment1   = p_segment1
AND   segment2   = p_segment2
AND   segment3   = p_segment3
AND   segment4   = p_segment4
AND   segment5   = '00000000'
AND   segment6   = '000000'
-- JP 12.2.4 AND   segment7   =  '000';
AND   segment7   =  '00000'
AND   chart_of_accounts_id =
     (SELECT chart_of_accounts_id
      FROM  gl_ledgers
      WHERE ledger_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID'));
--


W_KITS_SALDO   INSERTA_HIJOS_KITS%ROWTYPE;
W_MATERIAL_TRX INSERTA_HIJOS_TRX%ROWTYPE;
W_FECHA              DATE;
W_KIT_ID             NUMBER:=0;
W_FETCH_TRX          BOOLEAN;
W_CANTIDAD_PENDIENTE NUMBER;
W_CANTIDAD_TRX       NUMBER;
W_ORACLE_CR          VARCHAR2(5);
W_ORACLE_EF          VARCHAR2(5);
--W_CIA                VARCHAR2(3);
W_CIA                VARCHAR2(5);  --JP CRP 3.0
W_CUENTA             VARCHAR2(10);
W_CUENTA_KIT         VARCHAR2(10);
W_CCID_B             BOOLEAN;
W_CCID               NUMBER;
W_EOF                BOOLEAN;
W_COUNT_GPOTOTAL     NUMBER;
W_PIEVE              BOOLEAN;
W_COUNT_ART_PIEVE    NUMBER;
W_COUNT_TDA_PIEVE    NUMBER;
T_PERIOD_NUM         NUMBER;
T_PERIOD_YEAR        NUMBER;
T_COUNT              NUMBER;
T_ORACLE_EF          VARCHAR2(5);

ln_idPredecesor      NUMBER; --CHO 52104689

BEGIN
FND_FILE.PUT_LINE(FND_FILE.LOG,'Ingresa XXINV_KITS_CUENTAS_DIARIO' );

   W_FECHA := TRUNC(FND_CONC_DATE.STRING_TO_DATE(p_fecha));
   -------------------------   Extrae detallado de Salidas
   INSERT INTO XXINV_MATERIAL_TRX_TEMP --xxfc.XXINV_MATERIAL_TRX_TEMP --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
   (REQH_SEGMENT1_NO_REQUISICION,  REQH_REQUISITION_HEADER_ID,
        REQL_ATTRIBUTE2_CRSUP, MSI_SEGMENT1_NO_ARTICULO, MSI_DESCRIPCION, MSI_ATTRIBUTE1_USO,
        MSI_ATTRIBUTE2_MAE_ACTIVO, MSI_ATTRIBUTE3_CUENTA,MSI_ATTRIBUTE7_MAE_TIPO, MSI_ATTRIBUTE8_MAE_YN,
        MSI_ATTRIBUTE4_PARENT_MAND,MSI_ATTRIBUTE6_PARENT_HIJOS, REQL_ATTRIBUTE3_CR,AF_ORACLE_EF,
        MMT_TRANSACTION_ID, MMT_CREATION_DATE, MMT_CREATED_BY, MMT_INVENTORY_ITEM_ID,
        MMT_TRANSACTION_QUANTITY, MMT_TRANSACTION_DATE, MMT_DISTRIBUTION_ACCOUNT_ID,
        MMT_ACTUAL_COST, MMT_SOURCE_CODE, MMT_TRANSACTION_TYPE_ID, MMT_TRANSACTION_ACTION_ID,
        MMT_TRANSACTION_SOURCE_TYPE_ID, MMT_ORGANIZATION_ID,RL_LINE_ID,  RH_HEADER_ID,
        RL_ATTRIBUTE1_REQ_LINE_ID,AF_CCID, MSI_PURCHASING_TAX_CODE , MTA_GL_BATCH_ID,MMT_ATTRIBUTE15)
   SELECT  reqs.segment1 REQH_SEGMENT1_NO_REQUISICION,  REQS.REQUISITION_HEADER_ID REQH_REQUISITION_HEADER_ID,
--        reqs.attribute2 REQL_ATTRIBUTE2_CRSUP,
        XXINV_KITS_CUENTAS_DIARIO.BUSCA_REQUIS_CR_SUP(rl.attribute1) REQL_ATTRIBUTE2_CRSUP,
        msi.segment1 MSI_SEGMENT1_NO_ARTICULO, msi.description MSI_DESCRIPCION, MSI.ATTRIBUTE1 MSI_ATTRIBUTE1_USO,
        MSI.ATTRIBUTE2 MSI_ATTRIBUTE2_MAE_ACTIVO, MSI.ATTRIBUTE3, MSI.ATTRIBUTE7 MSI_ATTRIBUTE7_MAE_TIPO,
        MSI.ATTRIBUTE8 MSI_ATTRIBUTE8_MAE_YN, msi.attribute4 MSI_ATTRIBUTE4_PARENT_MAND,
        MSI.ATTRIBUTE6 MSI_ATTRIBUTE6_PARENT_HIJOS,
        XXINV_KITS_CUENTAS_DIARIO.BUSCA_REQUIS_CR(rl.attribute1) REQL_ATTRIBUTE3_CR,
        XXINV_KITS_CUENTAS_DIARIO.BUSCA_REQUIS_EF(rl.attribute1) AF_ORACLE_EF,
        MMT.TRANSACTION_ID  MMT_TRANSACTION_ID,    MMT.CREATION_DATE MMT_CREATION_DATE,MMT.CREATED_BY MMT_CREATED_BY,
        MMT.INVENTORY_ITEM_ID MMT_INVENTORY_ITEM_ID, MMT.TRANSACTION_QUANTITY MMT_TRANSACTION_QUANTITY,
        MMT.TRANSACTION_DATE MMT_TRANSACTION_DATE, MMT.DISTRIBUTION_ACCOUNT_ID MMT_DISTRIBUTION_ACCOUNT_ID,
        MMT.NEW_COST MMT_ACTUAL_COST, MMT.SOURCE_CODE MMT_SOURCE_CODE, MMT.TRANSACTION_TYPE_ID MMT_TRANSACTION_TYPE_ID,
        MMT.TRANSACTION_ACTION_ID MMT_TRANSACTION_ACTION_ID,  MMT.TRANSACTION_SOURCE_TYPE_ID MMT_TRANSACTION_SOURCE_TYPE_ID,
        MMT.ORGANIZATION_ID MMT_ORGANIZATION_ID,RL.LINE_ID RL_LINE_ID, RH.ORDER_NUMBER /*RH.HEADER_ID*ChO ***51967670***/ RH_HEADER_ID,RL.ATTRIBUTE1,
        MMT.DISTRIBUTION_ACCOUNT_ID AF_CCID,MSI.PURCHASING_TAX_CODE ,MTA.GL_BATCH_ID,MMT.ATTRIBUTE15
--        MMT.DISTRIBUTION_ACCOUNT_ID AF_CCID,MSI.PURCHASING_TAX_CODE ,MTA.GL_BATCH_ID,'20882028'
   from MTL_MATERIAL_TRANSACTIONS mmt, --inv.MTL_MATERIAL_TRANSACTIONS mmt, --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
        mtl_system_items_b msi, --inv.mtl_system_items_b msi, --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
        --inicio ChO ***51967670***
        --inv.MTL_TXN_REQUEST_HEADERS rh, --commet change WMS 25/03/2017**
        --inv.MTL_TXN_REQUEST_LINES rl, --commet change WMS 25/03/2017**
        oe_order_headers_all rh, --ont.oe_order_headers_all rh, --Add change WMS 25/03/2017**
        oe_order_lines_all rl, --ont.oe_order_lines_all rl,--Add change WMS 25/03/2017**
        --Fin ChO ***51967670***
        po_requisition_headers_all reqs, --po.po_requisition_headers_all reqs, --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
        mtl_transaction_accounts   mta --inv.mtl_transaction_accounts   mta --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
   --inicio ChO **51967670***
   WHERE  --mmt.transaction_type_id IN (63) --commet change WMS 25/03/2017**
         mmt.transaction_type_id IN (33)        --33-change Sales order issue WMS 23-03-17
   AND    mmt.transaction_action_id IN (1)
   --AND    mmt.transaction_source_type_id IN (4) --commet change WMS 25/03/2017**
   AND    mmt.transaction_source_type_id IN (2) --2-change Sales order issue WMS 23-03-17
   --Fin ChO ***51967670***
   and mmt.INVENTORY_ITEM_ID = msi.INVENTORY_ITEM_ID
   and msi.ORGANIZATION_ID = p_org_id
   and mmt.organization_id = p_org_id
   and rh.attribute2=to_char(reqs.REQUISITION_HEADER_ID)
   --inicio ChO ***51967670***
   --and rh.header_id = mmt.transaction_source_id --commet change WMS 25/03/2017**
   and rh.header_id = mmt.TRANSACTION_REFERENCE ---Add change WMS 25/03/2017**
   --Fin ChO 51967670
   and rh.header_id =  rl.header_id
   and mmt.trx_source_line_id        = rl.LINE_ID
   AND mta.ORGANIZATION_ID           =   mmt.ORGANIZATION_ID
   AND mta.TRANSACTION_ID            =   mmt.TRANSACTION_ID
--------------GDS abr-2010
--   AND mta.GL_BATCH_ID               != -1
 --  AND mmt.attribute12 IS NOT NULL      --  El proceso anterior los marco para indicar que son los que es estan procesando en el dia
--------------------
   AND mta.REFERENCE_ACCOUNT         =   mmt.DISTRIBUTION_ACCOUNT_ID
   AND trunc(mta.TRANSACTION_DATE)   =   trunc(w_fecha)
   AND trunc(mmt.CREATION_DATE) = Trunc(w_fecha)
   --inicio ChO ***51967670***
   --AND mta.accounting_line_type = 2;--commet change WMS 25/03/2017**
   AND mta.accounting_line_type = 36;--36-change(Deferred Cost of Goods Sold)WMS 23-03-17
   --Fin ChO ***51967670***
--------------GDS abr-2010 el proceso de preparacion llena estos campos
--   AND mmt.attribute10 IS NULL
--   AND mmt.attribute11 IS NULL;
-----------------------------------
      Fnd_File.Put_Line(Fnd_File.LOG,'ENTRA A LLENAR CAMPO DE COMPA?A');
-- llena campo de compa?
BEGIN
   FOR i IN ASIGNA_CIA (W_FECHA, P_ORG_ID) LOOP
      EXIT  WHEN ASIGNA_CIA%NOTFOUND;
      SELECT ORACLE_CIA INTO W_CIA
      FROM XXFC_MAESTRO_DE_CRS_V cr  --xxfc.XXFC_MAESTRO_DE_CRS_V cr --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
      WHERE oracle_cr = i.REQL_ATTRIBUTE3_CR
      AND   oracle_cr_superior  = i.REQL_ATTRIBUTE2_CRSUP
      AND   ORACLE_EF = i.AF_ORACLE_EF
--      AND ESTADO = 'A'
      AND ROWNUM=1;
      UPDATE XXINV_MATERIAL_TRX_TEMP --xxfc.XXINV_MATERIAL_TRX_TEMP --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
      SET AF_ORACLE_CIA = W_CIA
      WHERE CURRENT OF ASIGNA_CIA;
   END LOOP;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      fnd_file.put_line(fnd_file.LOG,'ASIGNA CIA NO encontro registros NO_DATA FOUND');

      WHEN TOO_MANY_ROWS THEN
      fnd_file.put_line(fnd_file.LOG,'ASIGNA CIA Encontro mas de un registro TOO_MANY_ROWS');
END;
Fnd_File.Put_Line(Fnd_File.LOG,'ANTES DE ENTRAR A LLENAR CALCULA KIT ITEM SALDO');
   ---  Barre TODOS articulos para calcular el saldo de c/Kit
BEGIN
   FOR i IN CALCULA_KIT_ITEM_SALDO (W_FECHA, P_ORG_ID) LOOP
      EXIT  WHEN CALCULA_KIT_ITEM_SALDO%NOTFOUND;
      SELECT  XXFC.XXINV_KIT_SALDO_DIARIO_S.NEXTVAL ID INTO W_KIT_ID FROM DUAL;
      INSERT INTO XXINV_KIT_SALDO_DIARIO --XXFC.XXINV_KIT_SALDO_DIARIO --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
      SELECT W_KIT_ID, TRUNC(MMT_CREATION_DATE),i.PARENT_MAND,
          MSI_SEGMENT1_NO_ARTICULO, REQL_ATTRIBUTE3_CR,AF_ORACLE_EF,
          i.CANTIDAD,0,SUM(MMT_TRANSACTION_QUANTITY*-1)
      FROM    XXINV_MATERIAL_TRX_TEMP XMT --xxfc.XXINV_MATERIAL_TRX_TEMP XMT --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
      WHERE    MMT_ORGANIZATION_ID = P_ORG_ID
      AND   TRUNC(MMT_CREATION_DATE) = TRUNC(W_FECHA)
      AND   REQL_ATTRIBUTE3_CR = i.ORACLE_CR
      AND   AF_ORACLE_EF = i.ORACLE_EF
      AND (msi_attribute6_parent_hijos LIKE ('%'||i.PARENT_MAND||'%') OR xmt.MSI_ATTRIBUTE4_PARENT_MAND=i.PARENT_MAND)
      GROUP BY W_KIT_ID,TRUNC(MMT_CREATION_DATE),i.PARENT_MAND,MSI_SEGMENT1_NO_ARTICULO,REQL_ATTRIBUTE3_CR,AF_ORACLE_EF,0,0;
   END LOOP;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      fnd_file.put_line(fnd_file.LOG,'CALCULA_KIT_ITEM_SALDO NO encontro registros NO_DATA FOUND');

      WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.LOG,'CALCULA_KIT_ITEM_SALDO Error OTHERS');

END;
  Fnd_File.Put_Line(Fnd_File.LOG,'DESPUES DE CALCULA KIT ITEM SALDO'||W_KIT_ID);

--llenar tabla de  Kits, articulo por articulo, iniciando con articulos mandatorios y luego articulos hijos
BEGIN
   FOR i IN INSERTA_MANDATORIOS_KITS (W_FECHA, P_ORG_ID) LOOP
      EXIT  WHEN INSERTA_MANDATORIOS_KITS%NOTFOUND;
---- busca y descuenta en kit_saldo_diario cada uno de los articulos de transactions
      UPDATE XXINV_KIT_SALDO_DIARIO SET SURTIDO = SURTIDO + i.MMT_TRANSACTION_QUANTITY --XXFC.XXINV_KIT_SALDO_DIARIO SET SURTIDO = SURTIDO + i.MMT_TRANSACTION_QUANTITY --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
           WHERE ITEM_NO = i.MSI_SEGMENT1_NO_ARTICULO
           AND ORACLE_CR = i.REQL_ATTRIBUTE3_CR
           AND ORACLE_EF = i.AF_ORACLE_EF;
        ---- inserta mandatorio en kits
      INSERT INTO XXINV_KIT_ITEMS_DIARIO (TRANSACTION_ID, --XXFC.XXINV_KIT_ITEMS_DIARIO (TRANSACTION_ID, --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
           ITEM_ID ,  PARENT_ITEM_NUMBER,   P_ORACLE_CR_SUPERIOR, P_ORACLE_CR,
           ORACLE_EF, MOVE_ORDER_HEADER_ID, QUANTITY,             REQ_HEADER_ID,
           REQ_LINE_ID,                     CREATION_DATE,        ITEM_NUMBER, LINE_NUM )
           VALUES (i.MMT_TRANSACTION_ID,
           i.MMT_INVENTORY_ITEM_ID, i.MSI_ATTRIBUTE4_PARENT_MAND,i.REQL_ATTRIBUTE2_CRSUP,i.REQL_ATTRIBUTE3_CR,
           i.AF_ORACLE_EF, i.RH_HEADER_ID, i.MMT_TRANSACTION_QUANTITY, i.REQH_REQUISITION_HEADER_ID,
           i.RL_ATTRIBUTE1_REQ_LINE_ID,i.MMT_CREATION_DATE,i.MSI_SEGMENT1_NO_ARTICULO,i.RL_LINE_ID);
   END LOOP INSERTA_MANDATORIOS_KITS;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      fnd_file.put_line(fnd_file.LOG,'INSERTA_MANDATORIOS_KITS NO encontro registros NO_DATA FOUND');

      WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.LOG,'INSERTA_MANDATORIOS_KITS Error OTHERS');

END;
  Fnd_File.Put_Line(Fnd_File.LOG,'DESPUES DE INSERTA_MANDATORIOS_KITS');
BEGIN
   OPEN INSERTA_HIJOS_KITS (W_FECHA);
   OPEN INSERTA_HIJOS_TRX (W_FECHA, P_ORG_ID);
   W_FETCH_TRX := TRUE;
   LOOP
      FETCH INSERTA_HIJOS_KITS INTO W_KITS_SALDO;
      EXIT WHEN INSERTA_HIJOS_KITS%NOTFOUND;
      W_CANTIDAD_PENDIENTE := W_KITS_SALDO.SALDO_PADRE - W_KITS_SALDO.SURTIDO;
      LOOP
         IF W_FETCH_TRX THEN
            FETCH INSERTA_HIJOS_TRX INTO W_MATERIAL_TRX;
            EXIT WHEN INSERTA_HIJOS_TRX%NOTFOUND;
            W_CANTIDAD_TRX := W_MATERIAL_TRX.MMT_TRANSACTION_QUANTITY*-1;
         END IF;
         W_EOF := TRUE;
         LOOP
            IF  W_KITS_SALDO.ORACLE_EF = W_MATERIAL_TRX.AF_ORACLE_EF     THEN
               IF W_KITS_SALDO.ORACLE_CR < W_MATERIAL_TRX.REQL_ATTRIBUTE3_CR THEN
                  FETCH INSERTA_HIJOS_KITS INTO W_KITS_SALDO;
                  EXIT WHEN INSERTA_HIJOS_KITS%NOTFOUND;
                  W_CANTIDAD_PENDIENTE := W_KITS_SALDO.SALDO_PADRE - W_KITS_SALDO.SURTIDO;
               ELSIF W_KITS_SALDO.ORACLE_CR > W_MATERIAL_TRX.REQL_ATTRIBUTE3_CR THEN
                  FETCH INSERTA_HIJOS_TRX INTO W_MATERIAL_TRX;
                  EXIT WHEN INSERTA_HIJOS_TRX%NOTFOUND;
                  W_CANTIDAD_TRX := W_MATERIAL_TRX.MMT_TRANSACTION_QUANTITY*-1;
               ELSIF W_KITS_SALDO.ORACLE_CR = W_MATERIAL_TRX.REQL_ATTRIBUTE3_CR  THEN
                  W_EOF := FALSE;
                  EXIT;
               END IF;
            ELSIF W_KITS_SALDO.ORACLE_EF > W_MATERIAL_TRX.AF_ORACLE_EF    THEN
                  FETCH INSERTA_HIJOS_TRX INTO W_MATERIAL_TRX;
                  EXIT WHEN INSERTA_HIJOS_TRX%NOTFOUND;
                  W_CANTIDAD_TRX := W_MATERIAL_TRX.MMT_TRANSACTION_QUANTITY*-1;
            ELSIF W_KITS_SALDO.ORACLE_EF < W_MATERIAL_TRX.AF_ORACLE_EF    THEN
                  FETCH INSERTA_HIJOS_KITS INTO W_KITS_SALDO;
                  EXIT WHEN INSERTA_HIJOS_KITS%NOTFOUND;
                  W_CANTIDAD_PENDIENTE := W_KITS_SALDO.SALDO_PADRE - W_KITS_SALDO.SURTIDO;
            END IF;

         END LOOP;
         IF W_EOF THEN
            EXIT;
         END IF;
--         FND_FILE.PUT_LINE(FND_FILE.LOG,'CR KIT HIJO = '||W_KITS_SALDO.ORACLE_CR );
--         FND_FILE.PUT_LINE(FND_FILE.LOG,'W_CANTIDAD PEND = '||W_CANTIDAD_PENDIENTE );
--         FND_FILE.PUT_LINE(FND_FILE.LOG,'CR KIT TRX '||W_MATERIAL_TRX.REQL_ATTRIBUTE3_CR );
--         FND_FILE.PUT_LINE(FND_FILE.LOG,'W_CANTIDAD_TRX '||W_CANTIDAD_TRX);
         IF W_KITS_SALDO.ITEM_NO = W_MATERIAL_TRX.MSI_SEGMENT1_NO_ARTICULO  THEN
            IF W_CANTIDAD_PENDIENTE >= W_CANTIDAD_TRX THEN
               UPDATE XXINV_KIT_SALDO_DIARIO --XXFC.XXINV_KIT_SALDO_DIARIO --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
               SET SURTIDO = SURTIDO +  W_CANTIDAD_TRX
               WHERE CURRENT OF INSERTA_HIJOS_KITS;

               UPDATE XXINV_MATERIAL_TRX_TEMP --xxfc.XXINV_MATERIAL_TRX_TEMP --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
               SET AF_TIPO_USO_CONVERTIDO = '04'
               WHERE CURRENT OF INSERTA_HIJOS_TRX;
               W_CANTIDAD_PENDIENTE := W_CANTIDAD_PENDIENTE - W_CANTIDAD_TRX;
               INSERT INTO XXINV_KIT_ITEMS_DIARIO (TRANSACTION_ID, --XXFC.XXINV_KIT_ITEMS_DIARIO (TRANSACTION_ID, --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
                  ITEM_ID ,  PARENT_ITEM_NUMBER,   P_ORACLE_CR_SUPERIOR, P_ORACLE_CR,
                  ORACLE_EF, MOVE_ORDER_HEADER_ID, QUANTITY,             REQ_HEADER_ID,
                  REQ_LINE_ID,                     CREATION_DATE,        ITEM_NUMBER, LINE_NUM )
               VALUES (W_MATERIAL_TRX.MMT_TRANSACTION_ID,
                  W_MATERIAL_TRX.MMT_INVENTORY_ITEM_ID, W_KITS_SALDO.PARENT_ID,   --W_MATERIAL_TRX.MSI_ATTRIBUTE6_PARENT_HIJOS,
                  W_MATERIAL_TRX.REQL_ATTRIBUTE2_CRSUP,W_MATERIAL_TRX.REQL_ATTRIBUTE3_CR,
                  W_MATERIAL_TRX.AF_ORACLE_EF, W_MATERIAL_TRX.RH_HEADER_ID, W_MATERIAL_TRX.MMT_TRANSACTION_QUANTITY*-1,
                    W_MATERIAL_TRX.REQH_REQUISITION_HEADER_ID,W_MATERIAL_TRX.RL_ATTRIBUTE1_REQ_LINE_ID,
                  W_MATERIAL_TRX.MMT_CREATION_DATE,W_MATERIAL_TRX.MSI_SEGMENT1_NO_ARTICULO,W_MATERIAL_TRX.RL_LINE_ID);
            ELSE
               IF W_CANTIDAD_PENDIENTE > 0 THEN
                  UPDATE XXINV_KIT_SALDO_DIARIO --XXFC.XXINV_KIT_SALDO_DIARIO --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
                  SET SURTIDO = SURTIDO +  W_CANTIDAD_PENDIENTE
                  WHERE CURRENT OF INSERTA_HIJOS_KITS;

                  UPDATE XXINV_MATERIAL_TRX_TEMP  --xxfc.XXINV_MATERIAL_TRX_TEMP --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
                  SET AF_TIPO_USO_CONVERTIDO = 'XX'
                  WHERE CURRENT OF INSERTA_HIJOS_TRX;

                  -- Inserta registro de sobrante  de Kit
                  W_MATERIAL_TRX.MMT_TRANSACTION_QUANTITY := (W_CANTIDAD_TRX - W_CANTIDAD_PENDIENTE)*-1;
                  W_MATERIAL_TRX.AF_STATUS_KITS := 'N';
                  INSERT INTO XXINV_MATERIAL_TRX_TEMP  --xxfc.XXINV_MATERIAL_TRX_TEMP --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
                  VALUES ( W_MATERIAL_TRX.REQH_SEGMENT1_NO_REQUISICION
                          ,W_MATERIAL_TRX.REQH_REQUISITION_HEADER_ID
                          ,W_MATERIAL_TRX.REQL_ATTRIBUTE2_CRSUP
                          ,W_MATERIAL_TRX.REQL_ATTRIBUTE3_CR
                          ,W_MATERIAL_TRX.MSI_SEGMENT1_NO_ARTICULO
                          ,W_MATERIAL_TRX.MSI_DESCRIPCION
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE1_USO
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE2_MAE_ACTIVO
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE3_CUENTA
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE7_MAE_TIPO
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE8_MAE_YN
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE4_PARENT_MAND
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE6_PARENT_HIJOS
                          ,W_MATERIAL_TRX.MSI_PURCHASING_TAX_CODE
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_ID
                          ,W_MATERIAL_TRX.MMT_CREATION_DATE
                          ,W_MATERIAL_TRX.MMT_CREATED_BY
                          ,W_MATERIAL_TRX.MMT_INVENTORY_ITEM_ID
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_QUANTITY
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_DATE
                          ,W_MATERIAL_TRX.MMT_DISTRIBUTION_ACCOUNT_ID
                          ,W_MATERIAL_TRX.MMT_ACTUAL_COST
                          ,W_MATERIAL_TRX.MMT_SOURCE_CODE
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE1
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE2
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE3
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE4
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE5
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE6
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE7
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE8
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE9
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE10
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE11
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE12
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE13
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE14
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE15
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_TYPE_ID
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_ACTION_ID
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_SOURCE_TYPE_ID
                          ,W_MATERIAL_TRX.MMT_ORGANIZATION_ID
                          ,W_MATERIAL_TRX.MTA_GL_BATCH_ID
                          ,W_MATERIAL_TRX.RL_LINE_ID
                          ,W_MATERIAL_TRX.RH_HEADER_ID
                          ,W_MATERIAL_TRX.RL_ATTRIBUTE1_REQ_LINE_ID
                          ,W_MATERIAL_TRX.AF_ORACLE_EF
                          ,W_MATERIAL_TRX.AF_ORACLE_CIA
                          ,W_MATERIAL_TRX.AF_CCID
                          ,W_MATERIAL_TRX.AF_INTERFACE_TYPE
                          ,W_MATERIAL_TRX.AF_TIPO_USO_CONVERTIDO
                          ,W_MATERIAL_TRX.AF_STATUS_KITS
                          ,W_MATERIAL_TRX.AF_STATUS_CUENTAS );

               -- Inserta registro de pendiente de surtir en Kit
                  W_MATERIAL_TRX.AF_TIPO_USO_CONVERTIDO := '04';
                  W_MATERIAL_TRX.MMT_TRANSACTION_QUANTITY := W_CANTIDAD_PENDIENTE*-1;
                  INSERT INTO XXINV_MATERIAL_TRX_TEMP  --xxfc.XXINV_MATERIAL_TRX_TEMP --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
                  VALUES ( W_MATERIAL_TRX.REQH_SEGMENT1_NO_REQUISICION
                          ,W_MATERIAL_TRX.REQH_REQUISITION_HEADER_ID
                          ,W_MATERIAL_TRX.REQL_ATTRIBUTE2_CRSUP
                          ,W_MATERIAL_TRX.REQL_ATTRIBUTE3_CR
                          ,W_MATERIAL_TRX.MSI_SEGMENT1_NO_ARTICULO
                          ,W_MATERIAL_TRX.MSI_DESCRIPCION
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE1_USO
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE2_MAE_ACTIVO
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE3_CUENTA
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE7_MAE_TIPO
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE8_MAE_YN
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE4_PARENT_MAND
                          ,W_MATERIAL_TRX.MSI_ATTRIBUTE6_PARENT_HIJOS
                          ,W_MATERIAL_TRX.MSI_PURCHASING_TAX_CODE
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_ID
                          ,W_MATERIAL_TRX.MMT_CREATION_DATE
                          ,W_MATERIAL_TRX.MMT_CREATED_BY
                          ,W_MATERIAL_TRX.MMT_INVENTORY_ITEM_ID
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_QUANTITY
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_DATE
                          ,W_MATERIAL_TRX.MMT_DISTRIBUTION_ACCOUNT_ID
                          ,W_MATERIAL_TRX.MMT_ACTUAL_COST
                          ,W_MATERIAL_TRX.MMT_SOURCE_CODE
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE1
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE2
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE3
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE4
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE5
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE6
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE7
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE8
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE9
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE10
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE11
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE12
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE13
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE14
                          ,W_MATERIAL_TRX.MMT_ATTRIBUTE15
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_TYPE_ID
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_ACTION_ID
                          ,W_MATERIAL_TRX.MMT_TRANSACTION_SOURCE_TYPE_ID
                          ,W_MATERIAL_TRX.MMT_ORGANIZATION_ID
                          ,W_MATERIAL_TRX.MTA_GL_BATCH_ID
                          ,W_MATERIAL_TRX.RL_LINE_ID
                          ,W_MATERIAL_TRX.RH_HEADER_ID
                          ,W_MATERIAL_TRX.RL_ATTRIBUTE1_REQ_LINE_ID
                          ,W_MATERIAL_TRX.AF_ORACLE_EF
                          ,W_MATERIAL_TRX.AF_ORACLE_CIA
                          ,W_MATERIAL_TRX.AF_CCID
                          ,W_MATERIAL_TRX.AF_INTERFACE_TYPE
                          ,W_MATERIAL_TRX.AF_TIPO_USO_CONVERTIDO
                          ,W_MATERIAL_TRX.AF_STATUS_KITS
                          ,W_MATERIAL_TRX.AF_STATUS_CUENTAS );

                  W_CANTIDAD_PENDIENTE := W_CANTIDAD_PENDIENTE - W_CANTIDAD_TRX;
               INSERT INTO XXINV_KIT_ITEMS_DIARIO (TRANSACTION_ID,  --XXFC.XXINV_KIT_ITEMS_DIARIO (TRANSACTION_ID, --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
                  ITEM_ID ,  PARENT_ITEM_NUMBER,   P_ORACLE_CR_SUPERIOR, P_ORACLE_CR,
                  ORACLE_EF, MOVE_ORDER_HEADER_ID, QUANTITY,             REQ_HEADER_ID,
                  REQ_LINE_ID,                     CREATION_DATE,        ITEM_NUMBER, LINE_NUM )
               VALUES (W_MATERIAL_TRX.MMT_TRANSACTION_ID,
                  W_MATERIAL_TRX.MMT_INVENTORY_ITEM_ID, W_KITS_SALDO.PARENT_ID,   --W_MATERIAL_TRX.MSI_ATTRIBUTE6_PARENT_HIJOS,
                  W_MATERIAL_TRX.REQL_ATTRIBUTE2_CRSUP,W_MATERIAL_TRX.REQL_ATTRIBUTE3_CR,
                  W_MATERIAL_TRX.AF_ORACLE_EF, W_MATERIAL_TRX.RH_HEADER_ID, W_MATERIAL_TRX.MMT_TRANSACTION_QUANTITY*-1,
                    W_MATERIAL_TRX.REQH_REQUISITION_HEADER_ID,W_MATERIAL_TRX.RL_ATTRIBUTE1_REQ_LINE_ID,
                  W_MATERIAL_TRX.MMT_CREATION_DATE,W_MATERIAL_TRX.MSI_SEGMENT1_NO_ARTICULO,W_MATERIAL_TRX.RL_LINE_ID);
               END IF;

            END IF;
            W_FETCH_TRX := TRUE;

         ELSIF W_KITS_SALDO.ITEM_NO > W_MATERIAL_TRX.MSI_SEGMENT1_NO_ARTICULO  THEN
            IF W_MATERIAL_TRX.AF_ORACLE_EF = W_KITS_SALDO.ORACLE_EF
               AND  W_MATERIAL_TRX.REQL_ATTRIBUTE3_CR = W_KITS_SALDO.ORACLE_CR THEN
               W_FETCH_TRX := TRUE;
            ELSE
               W_FETCH_TRX := FALSE;
               EXIT;
            END IF;
         ELSIF W_KITS_SALDO.ITEM_NO < W_MATERIAL_TRX.MSI_SEGMENT1_NO_ARTICULO  THEN
            W_FETCH_TRX := FALSE;
            EXIT;

         END IF;
      END LOOP;

   END LOOP;
   CLOSE INSERTA_HIJOS_TRX;
   CLOSE INSERTA_HIJOS_KITS;
   DELETE FROM XXINV_MATERIAL_TRX_TEMP WHERE AF_TIPO_USO_CONVERTIDO = 'XX';  --xxfc.XXINV_MATERIAL_TRX_TEMP WHERE AF_TIPO_USO_CONVERTIDO = 'XX'; --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      fnd_file.put_line(fnd_file.LOG,'INSERTA_HIJOS_KITS NO encontro registros NO_DATA FOUND');

      WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.LOG,'INSERTA_HIJOS_KITS Error OTHERS');

END;
  Fnd_File.Put_Line(Fnd_File.LOG,'DESPUES DE INSERTA_HIJOS_KITS');
BEGIN
--- Asignar cuenta contable ***
   FOR i IN ASIGNA_CUENTA (W_FECHA, P_ORG_ID) LOOP
      EXIT  WHEN ASIGNA_CUENTA%NOTFOUND;
      W_ORACLE_CR := i.REQL_ATTRIBUTE3_CR;
      W_CIA := i.AF_ORACLE_CIA;
-- Determina si es PIEVE para marcar la ccid con -1
      W_PIEVE := FALSE;
      W_CCID := i.MMT_DISTRIBUTION_ACCOUNT_ID;
      IF ( (TO_NUMBER(SUBSTR(W_ORACLE_CR,1,2)) BETWEEN 50 AND 80) OR (TO_NUMBER(SUBSTR(W_ORACLE_CR,1,2))) = 10 ) THEN
--   Revisa si el articulo esta en la lista de valores PIEVE
         SELECT count(*) INTO W_COUNT_ART_PIEVE
            FROM fnd_flex_value_sets fvs, fnd_flex_values_vl ffv
           WHERE fvs.flex_value_set_name = 'XXINV_AF_ARTICULOS_PIEVE'
             AND fvs.flex_value_set_id   = ffv.flex_value_set_id
             AND ffv.enabled_flag = 'Y'
           AND ffv.flex_value = i.MSI_SEGMENT1_NO_ARTICULO;

         IF W_COUNT_ART_PIEVE > 0 THEN  -- SI es articulo PIEVE
--   Revisa si la tienda  esta en la lista de valores PIEVE
            SELECT count(*) INTO W_COUNT_TDA_PIEVE
               FROM fnd_flex_value_sets fvs, fnd_flex_values_vl ffv
              WHERE fvs.flex_value_set_name = 'XXINV_AF_TIENDAS_PIEVE'
                AND fvs.flex_value_set_id   = ffv.flex_value_set_id
                AND ffv.enabled_flag = 'Y'
                AND ffv.flex_value = i.REQL_ATTRIBUTE2_CRSUP||i.REQL_ATTRIBUTE3_CR
                AND TO_DATE(ffv.description,'DD/MM/RRRR') >= W_FECHA;
             IF W_COUNT_TDA_PIEVE > 0 THEN  -- SI es tienda PIEVE
                -- Revisa si la tienda tiena mas de 3 meses
                -- Inicia CHO 51413405
                -- Tiendas que vienen de OxxoExpress
/*                IF  i.AF_ORACLE_EF = '01MAF' AND SYSDATE <= '31-AUG-2013'  THEN
                    T_ORACLE_EF := '01MAM';
                ELSIF i.AF_ORACLE_EF = '01PBF' AND SYSDATE <= '30-SEP-2013'  THEN
                    T_ORACLE_EF := '01PBC';
                ELSIF i.AF_ORACLE_EF = '01CUF' AND SYSDATE <= '31-OCT-2013'  THEN
                    T_ORACLE_EF := '01CUU';
                ELSIF i.AF_ORACLE_EF = '01QRF' AND SYSDATE <= '31-OCT-2013'  THEN
                    T_ORACLE_EF := '01QRO';
                ELSIF i.AF_ORACLE_EF = '01SLF' AND SYSDATE <= '31-OCT-2013'  THEN
                    T_ORACLE_EF := '01SLW';
                ELSE
                    T_ORACLE_EF := i.AF_ORACLE_EF;
                END IF;
                --
*/
                T_ORACLE_EF := i.AF_ORACLE_EF;
                -- Fin CHO 51413405

                --Inicia CHO 52104689
                --Se busca predecesor de CR
                ln_idPredecesor := NULL;

                BEGIN
                      SELECT xcr_id_predecesor
                      INTO   ln_idPredecesor
				      FROM   apps.xxfc_centros_responsabilidad xcr,
                             apps.xxfc_estados_financieros xef
                      WHERE  1 =1
                      AND    xcr.xef_id_estado_financiero = xef.id_estado_financiero
                      AND    xef.oracle_ef =  t_oracle_ef
                      AND    xcr.oracle_cr =  w_oracle_cr
                      AND    xcr.xcr_id_predecesor IS NOT NULL;
                EXCEPTION
                   WHEN OTHERS THEN
                      ln_idPredecesor := NULL;
                END;

                --Se obtiene CR y EF predecesor
                IF ln_idPredecesor IS NOT NULL THEN
                   BEGIN
                         SELECT xef.oracle_ef
                               ,xcr.oracle_cr
                         INTO   t_oracle_ef
                               ,w_oracle_cr
				         FROM   apps.xxfc_centros_responsabilidad xcr,
                                apps.xxfc_estados_financieros xef
                         WHERE  1 =1
                         AND    xcr.xef_id_estado_financiero = xef.id_estado_financiero
                         AND    xcr.xcr_id_predecesor = ln_idPredecesor;
                   EXCEPTION
                      WHEN OTHERS THEN
                         NULL;
                   END;
                END IF;

                --Se calculan 3 meses antes a la echa del periodo actual
                T_PERIOD_NUM := TO_NUMBER(TO_CHAR(SYSDATE,'MM')) - 4;
                T_PERIOD_YEAR := TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'));

                IF T_PERIOD_NUM < 1 THEN
                   T_PERIOD_NUM := T_PERIOD_NUM + 12;
                   T_PERIOD_YEAR := T_PERIOD_YEAR - 1;
                END IF;

                --Se valida si el CR actual o predecesor tiene mas de 3 meses
                SELECT COUNT(*)
                INTO   T_COUNT
                FROM   GL_BALANCES
                WHERE  PERIOD_NUM <= T_PERIOD_NUM
                AND    PERIOD_YEAR = T_PERIOD_YEAR
                AND    CODE_COMBINATION_ID IN (SELECT CODE_COMBINATION_ID FROM GL_CODE_COMBINATIONS
                                               WHERE  SEGMENT4 IN ('51AP0001', '51AP0003', '51AP5000', '51AP5002', '51AP5003')
                                               AND    SEGMENT3 = W_ORACLE_CR
                                               AND    SEGMENT2 = T_ORACLE_EF)
-- JP 12.2.4                AND    LEDGER_ID = 1;
                AND    LEDGER_ID = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');

                IF T_COUNT > 0 THEN -- Tienda es mas de 3 meses
                   W_CCID := -99999 ;
                   W_PIEVE := TRUE;
                END IF;--- Fin CHO 52104689

             END IF;
         END IF;
      END IF;
      IF NOT W_PIEVE THEN
         SELECT COUNT(*) INTO W_COUNT_GPOTOTAL
           FROM fnd_flex_value_sets fvs, fnd_flex_values_vl ffv
          WHERE fvs.flex_value_set_name = 'XXINV_AF_GPOTOTAL'
            AND fvs.flex_value_set_id   = ffv.flex_value_set_id
            AND ffv.enabled_flag = 'Y'
            AND ffv.flex_value = NVL(i.MSI_ATTRIBUTE2_MAE_ACTIVO,'XXXX');
         IF i.MSI_ATTRIBUTE1_USO IN('03','01') THEN
            CHECK_ITEM_ACCOUNT(i.MMT_INVENTORY_ITEM_ID,P_ORG_ID,i.AF_ORACLE_EF,W_ORACLE_CR,
            W_CUENTA,i.RL_ATTRIBUTE1_REQ_LINE_ID,i.REQH_REQUISITION_HEADER_ID);
         ELSIF (i.MSI_ATTRIBUTE1_USO = '04' AND  W_COUNT_GPOTOTAL > 0 ) THEN           -- IN GPOTOTAL
            CHECK_ITEM_ACCOUNT(i.MMT_INVENTORY_ITEM_ID,P_ORG_ID,i.AF_ORACLE_EF,W_ORACLE_CR,
            W_CUENTA,i.RL_ATTRIBUTE1_REQ_LINE_ID,i.REQH_REQUISITION_HEADER_ID);
         ELSIF (i.MSI_ATTRIBUTE1_USO = '04' AND  W_COUNT_GPOTOTAL = 0 ) THEN           ---NOT IN    GPOTOTAL
            W_ORACLE_CR := i.REQL_ATTRIBUTE2_CRSUP;
            W_CUENTA := i.MSI_ATTRIBUTE3_CUENTA;

         END IF;
         IF NVL(i.AF_TIPO_USO_CONVERTIDO,'01') = '04' THEN
            W_ORACLE_CR := i.REQL_ATTRIBUTE2_CRSUP;
            W_CUENTA := W_CUENTA_KIT;
         ELSE
            IF i.MSI_ATTRIBUTE4_PARENT_MAND is not null THEN
               W_CUENTA_KIT := W_CUENTA;
            END IF;
         END IF;
--               IF t_attribute1 = '01'  AND t_attribute7 = 'KIT' THEN
         W_CCID_B :=  TRUE;
         OPEN c_code_combination_id (W_CIA,i.AF_ORACLE_EF,W_ORACLE_CR,W_CUENTA);
         LOOP
            FETCH c_code_combination_id INTO  W_CCID;
            EXIT WHEN c_code_combination_id%NOTFOUND;
            W_CCID_B := FALSE;
         END LOOP;
         CLOSE c_code_combination_id;
         IF W_CCID_B THEN
            BEGIN
               create_code_combination(W_CIA,i.AF_ORACLE_EF,W_ORACLE_CR,W_CUENTA,W_CCID,retcode,errbuf);
               IF retcode = 1 THEN
--               Fnd_File.Put_Line(Fnd_File.LOG,'No puede crear Code combination para '||
--                                 W_CIA||' '||i.AF_ORACLE_EF||' '||W_CUENTA);
--               Fnd_File.Put_Line(Fnd_File.LOG,'debido a :'||errbuf);
               W_CCID_B :=  FALSE; --quitar cuando se quite los coments
               END IF;
            END;
         END IF;
      END IF; -- NOT W_PIEVE

      UPDATE XXINV_MATERIAL_TRX_TEMP  --xxfc.XXINV_MATERIAL_TRX_TEMP --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
      SET MMT_DISTRIBUTION_ACCOUNT_ID = W_CCID
      WHERE CURRENT OF ASIGNA_CUENTA;
   END LOOP;
--- Cambia tipo uso
   FOR i IN ASIGNA_CUENTA (W_FECHA, P_ORG_ID) LOOP
      EXIT  WHEN ASIGNA_CUENTA%NOTFOUND;
      IF i.MMT_DISTRIBUTION_ACCOUNT_ID = -99999 THEN
         INSERT INTO XXINV_CHANGE_ITEM_ATTRIBUTE_KC(ITEM_ID,CHANGE_DATE,ORGANIZATION_ID,ORG_ATTRIBUTE1,CHANGE_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID)
         VALUES (i.MMT_INVENTORY_ITEM_ID,SYSDATE,P_ORG_ID,i.msi_attribute1_uso,'04',i.RL_ATTRIBUTE1_REQ_LINE_ID,i.REQH_REQUISITION_HEADER_ID);
      END IF; ---CCID = -1
   END LOOP;
--- Actualiza los datos que se neceistan para agrupar el activo.
   UPDATE XXINV_MATERIAL_TRX_TEMP  --xxfc.XXINV_MATERIAL_TRX_TEMP --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
   SET msi_attribute7_mae_tipo = 'GPOTOTAL',msi_attribute1_uso =  '04',
       --Inicia CHO 51988424
       --msi_attribute2_mae_activo = 'G.41', af_interface_type = NULL
       af_interface_type = NULL
       --Termina CHO 51988424
   WHERE MMT_DISTRIBUTION_ACCOUNT_ID = -99999;
--- Asignar cuenta contable  a articulos  PIEVE
   FOR i IN ASIGNA_CUENTA (W_FECHA, P_ORG_ID) LOOP
      EXIT  WHEN ASIGNA_CUENTA%NOTFOUND;
      IF i.MMT_DISTRIBUTION_ACCOUNT_ID = -99999 THEN
         W_CUENTA := '24ME0045';
         W_CCID_B :=  TRUE;
         OPEN c_code_combination_id (i.AF_ORACLE_CIA,i.AF_ORACLE_EF,i.REQL_ATTRIBUTE2_CRSUP,W_CUENTA);
         LOOP
            FETCH c_code_combination_id INTO  W_CCID;
            EXIT WHEN c_code_combination_id%NOTFOUND;
            W_CCID_B := FALSE;
         END LOOP;
         CLOSE c_code_combination_id;
         IF W_CCID_B THEN
            BEGIN
               create_code_combination(W_CIA,i.AF_ORACLE_EF,W_ORACLE_CR,W_CUENTA,W_CCID,retcode,errbuf);
               IF retcode = 1 THEN
                  W_CCID_B :=  FALSE;
               END IF;
            END;
         END IF;
         UPDATE XXINV_MATERIAL_TRX_TEMP  --xxfc.XXINV_MATERIAL_TRX_TEMP --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
         SET MMT_DISTRIBUTION_ACCOUNT_ID = W_CCID
         WHERE CURRENT OF ASIGNA_CUENTA;
      END IF; ---CCID = -1

   END LOOP;
   EXCEPTION
      WHEN OTHERS THEN
      Fnd_File.Put_Line(Fnd_File.LOG,'Ocurrio error en ASIGNA CUENTA');
      Fnd_File.Put_Line(Fnd_File.LOG,'mensaje de error : '||SQLERRM);

END;
  Fnd_File.Put_Line(Fnd_File.LOG,'DESPUES DE ASIGNA_CUENTA');

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      fnd_file.put_line(fnd_file.LOG,'NO encontro registros NO_DATA FOUND');

      WHEN TOO_MANY_ROWS THEN
      fnd_file.put_line(fnd_file.LOG,'Encontro mas de un registro TOO_MANY_ROWS');

      WHEN OTHERS THEN
      Fnd_File.Put_Line(Fnd_File.LOG,'Ocurrio error en XXINV_KITS_CUENTAS_DIARIO');
      Fnd_File.Put_Line(Fnd_File.LOG,'mensaje de error : '||SQLERRM);



END Main;


FUNCTION BUSCA_REQUIS_CR(P_REQ_LINE NUMBER)RETURN VARCHAR2 IS
W_REQ_CR VARCHAR2(6);
BEGIN
   select attribute3 INTO W_REQ_CR
   from po_requisition_lines_all --po.po_requisition_lines_all --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
   where REQUISITION_LINE_ID = P_REQ_LINE
   and rownum=1;
   RETURN W_REQ_CR;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RETURN 'XXXXX';
END BUSCA_REQUIS_CR;

FUNCTION BUSCA_REQUIS_CR_SUP(P_REQ_LINE NUMBER)RETURN VARCHAR2 IS
W_REQ_CR_SUP VARCHAR2(6);
BEGIN
   select attribute2 INTO W_REQ_CR_SUP
   from po_requisition_lines_all --po.po_requisition_lines_all --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
   where REQUISITION_LINE_ID = P_REQ_LINE
   and rownum=1;
   RETURN W_REQ_CR_SUP;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RETURN 'XXXXX';
END BUSCA_REQUIS_CR_SUP;

FUNCTION BUSCA_REQUIS_EF(P_REQ_LINE NUMBER)RETURN VARCHAR2 IS
W_REQ_EF VARCHAR2(5);
BEGIN
   select ORACLE_EF into W_REQ_EF
   from po_requisition_lines_all RLA, XXFC_MAESTRO_DE_CRS_V MAE --po.po_requisition_lines_all RLA, XXFC_MAESTRO_DE_CRS_V MAE --23/Abr/2018 EMMR Consiss  Upgrade R12.2.4
   where REQUISITION_LINE_ID = P_REQ_LINE
   AND ROWNUM = 1
   AND RLA.ATTRIBUTE2 = MAE.ORACLE_CR_SUPERIOR
   AND RLA.ATTRIBUTE3 = MAE.ORACLE_CR
   AND MAE.ESTADO = 'A';
   RETURN W_REQ_EF;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RETURN 'XXXXX';
END BUSCA_REQUIS_EF;


PROCEDURE CHECK_ITEM_ACCOUNT(P_ITEM_ID IN NUMBER,
        P_ORGANIZATION_ID IN NUMBER,
        P_ORACLE_EF IN VARCHAR2,
        P_ORACLE_CR IN OUT VARCHAR2,
        P_CUENTA OUT VARCHAR2,
        PR_LINE_ID IN NUMBER,
        PR_HEADER_ID IN NUMBER
        ) IS
T_ATTRIBUTE1 VARCHAR2(10);
T_ATTRIBUTE2 VARCHAR2(10);
T_ATTRIBUTE7 VARCHAR2(10);
T_SEGMENT1 VARCHAR2(10);
T_SEGMENT2 VARCHAR2(10);
T_SEGMENT3 VARCHAR2(10);
T_SEGMENT4 VARCHAR2(10);
T_SEGMENT5 VARCHAR2(10);
T_SEGMENT6 VARCHAR2(10);
T_SEGMENT7 VARCHAR2(10);
T_ATTRIBUTE3 VARCHAR2(10);
T_NEW_SEGMENT4 VARCHAR2(10);
T_CHANGE_SEGMENT VARCHAR2(10);
T_COUNT NUMBER;
T_COUNT_GPOTOTAL NUMBER;
T_FLAG VARCHAR2(1) := 'N';
T_ORACLE_CR VARCHAR2(100);
T_PERIOD_NUM NUMBER;
T_PERIOD_YEAR NUMBER;
T_ORACLE_EF VARCHAR2(5);
-- Inicia CHO 51413405
ln_CuentaTienda        NUMBER;
lv_OracleCrSuperior    VARCHAR2(5);
-- Fin CHO 51413405

ln_idPredecesor   NUMBER;  --CHO 52104689

BEGIN
--DBMS_OUTPUT.PUT_LINE(' I AM IN PROCEDURE CHECK_ITEM_ACCOUNT');

/* TAKING ITEM ATTRIBUTES AND SEGMENTS */
BEGIN

  SELECT MSI.ATTRIBUTE1,MSI.ATTRIBUTE2,MSI.ATTRIBUTE3,MSI.ATTRIBUTE7,GLC.SEGMENT1,GLC.SEGMENT2,GLC.SEGMENT3,GLC.SEGMENT4,GLC.SEGMENT5,GLC.SEGMENT6,GLC.SEGMENT7
  INTO   T_ATTRIBUTE1,T_ATTRIBUTE2,T_ATTRIBUTE3,T_ATTRIBUTE7,T_SEGMENT1,T_SEGMENT2,T_SEGMENT3,T_SEGMENT4,T_SEGMENT5,T_SEGMENT6,T_SEGMENT7
  FROM MTL_SYSTEM_ITEMS MSI,
       GL_CODE_COMBINATIONS GLC
  WHERE MSI.INVENTORY_ITEM_ID = P_ITEM_ID
  AND   MSI.ORGANIZATION_ID = P_ORGANIZATION_ID
  AND   MSI.EXPENSE_ACCOUNT = GLC.CODE_COMBINATION_ID;
EXCEPTION
WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('ERROR IN ITEM PICKING');
END;
SELECT COUNT(*) INTO T_COUNT_GPOTOTAL
  FROM fnd_flex_value_sets fvs, fnd_flex_values_vl ffv
 WHERE fvs.flex_value_set_name = 'XXINV_AF_GPOTOTAL'
   AND fvs.flex_value_set_id   = ffv.flex_value_set_id
   AND ffv.enabled_flag = 'Y'
   AND ffv.flex_value = NVL(T_ATTRIBUTE2,'XXXXX');

IF ( (TO_NUMBER(SUBSTR(P_ORACLE_CR,1,2)) BETWEEN 50 AND 80) OR (TO_NUMBER(SUBSTR(P_ORACLE_CR,1,2))) = 10 ) THEN
/* Revisa el registro de las cuentas de ventas del CR */
    -- Inicia CHO 51413405
    -- Tiendas que vienen de OxxoExpress
/*    IF  P_ORACLE_EF = '01MAF' AND SYSDATE <= '31-AUG-2013'  THEN
        T_ORACLE_EF := '01MAM';
    ELSIF P_ORACLE_EF = '01PBF' AND SYSDATE <= '30-SEP-2013'  THEN
        T_ORACLE_EF := '01PBC';
    ELSIF P_ORACLE_EF = '01CUF' AND SYSDATE <= '31-OCT-2013'  THEN
        T_ORACLE_EF := '01CUU';
    ELSIF P_ORACLE_EF = '01QRF' AND SYSDATE <= '31-OCT-2013'  THEN
        T_ORACLE_EF := '01QRO';
    ELSIF P_ORACLE_EF = '01SLF' AND SYSDATE <= '31-OCT-2013'  THEN
        T_ORACLE_EF := '01SLW';
    ELSE
        T_ORACLE_EF := P_ORACLE_EF;
    END IF;
    --
*/
    T_ORACLE_EF := P_ORACLE_EF;
    -- Fin CHO 51413405

    --Inicia CHO 52104689
    --Se busca predecesor de CR
    ln_idPredecesor := NULL;

    BEGIN
       SELECT xcr_id_predecesor
       INTO   ln_idPredecesor
	   FROM   apps.xxfc_centros_responsabilidad xcr,
              apps.xxfc_estados_financieros xef
       WHERE  1 =1
       AND    xcr.xef_id_estado_financiero = xef.id_estado_financiero
       AND    xef.oracle_ef =  T_ORACLE_EF
       AND    xcr.oracle_cr =  P_ORACLE_CR
       AND    xcr.xcr_id_predecesor IS NOT NULL;
    EXCEPTION
       WHEN OTHERS THEN
          ln_idPredecesor := NULL;
    END;

    --Se obtiene CR y EF predecesor
    IF ln_idPredecesor IS NOT NULL THEN
       BEGIN
          SELECT xef.oracle_ef
                ,xcr.oracle_cr
          INTO   T_ORACLE_EF
                ,P_ORACLE_CR
		  FROM   apps.xxfc_centros_responsabilidad xcr,
                 apps.xxfc_estados_financieros xef
          WHERE  1 =1
          AND    xcr.xef_id_estado_financiero = xef.id_estado_financiero
          AND    xcr.xcr_id_predecesor = ln_idPredecesor;
        EXCEPTION
          WHEN OTHERS THEN
             NULL;
        END;
    END IF;

    --Se calculan 3 meses antes a la echa del periodo actual
    T_PERIOD_NUM := TO_NUMBER(TO_CHAR(SYSDATE,'MM')) - 4;
    T_PERIOD_YEAR := TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'));

    IF T_PERIOD_NUM < 1 THEN
       T_PERIOD_NUM := T_PERIOD_NUM + 12;
       T_PERIOD_YEAR := T_PERIOD_YEAR - 1;
    END IF;

    --Se valida si el CR actual o predecesor tiene mas de 3 meses
    SELECT COUNT(*)
    INTO   T_COUNT
    FROM   GL_BALANCES
    WHERE  PERIOD_NUM <= T_PERIOD_NUM
    AND    PERIOD_YEAR = T_PERIOD_YEAR
    AND    CODE_COMBINATION_ID IN (SELECT CODE_COMBINATION_ID FROM GL_CODE_COMBINATIONS
                                   WHERE  SEGMENT4 IN ('51AP0001', '51AP0003', '51AP5000', '51AP5002', '51AP5003')
                                   AND    SEGMENT3 = P_ORACLE_CR
                                   -- Tiendas que vienen de OxxoExpress
                                   --       AND SEGMENT2 = P_ORACLE_EF)
                                   AND    SEGMENT2 = T_ORACLE_EF)
    --
    -- JP 12.2.4    AND    LEDGER_ID = 1;
    AND    LEDGER_ID = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');

    IF NVL(T_COUNT,0) > 0 THEN
       T_FLAG := 'Y';
    ELSE
       T_FLAG := 'N';
    END IF;--- Fin CHO 52104689

    /* CHECKING FOR THE ITEM ATTRIBUTE CHANGES IN THE CASE OF 03 AND IF IT IS ISSUED FROM THE STORES*/

    IF T_FLAG = 'Y' AND T_ATTRIBUTE1 = '03' THEN
       T_ATTRIBUTE1 := '01';
       -- Inicia CHO 51413405
       BEGIN
          SELECT Oracle_Cr_Superior
          INTO lv_OracleCrSuperior
          FROM xxfc_maestro_de_crs_v
          WHERE Oracle_Cr = P_Oracle_Cr
          AND   Oracle_Ef = P_Oracle_Ef
          AND ROWNUM = 1 ;
          EXCEPTION
          WHEN OTHERS THEN
          Fnd_File.Put_Line(Fnd_File.LOG,'No se encontro el CR Superior');
       END;
       --   Revisa si la tienda  esta en la lista de valores de tiendas a REMODELAR
       SELECT count(*) INTO ln_CuentaTienda
       FROM fnd_flex_value_sets fvs, fnd_flex_values_vl ffv
       WHERE fvs.flex_value_set_name = 'XXINV_AF_TIENDAS_REMODELAR'
       AND fvs.flex_value_set_id   = ffv.flex_value_set_id
       AND ffv.enabled_flag = 'Y'
       AND ffv.flex_value = lv_OracleCrSuperior||P_ORACLE_CR
       AND TO_DATE(ffv.description,'DD/MM/RRRR') >= SYSDATE;
       IF ln_CuentaTienda > 0 THEN  -- SI es tienda a Remodelar
          T_Segment4 := '26AC0025';
       ELSE
          T_Segment4 := '72IF0877';
       END IF;
       -- Fin CHO 51413405
    INSERT INTO XXINV_CHANGE_ITEM_ATTRIBUTE_KC(ITEM_ID,CHANGE_DATE,ORGANIZATION_ID,ORG_ATTRIBUTE1,CHANGE_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID)
                                    VALUES (P_ITEM_ID,SYSDATE,P_ORGANIZATION_ID,'03',T_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID);
    ELSIF T_FLAG = 'N' AND T_ATTRIBUTE1 = '03' THEN
       T_ATTRIBUTE1 := '04';
       T_ATTRIBUTE3 := '26AC0025';
    INSERT INTO XXINV_CHANGE_ITEM_ATTRIBUTE_KC(ITEM_ID,CHANGE_DATE,ORGANIZATION_ID,ORG_ATTRIBUTE1,CHANGE_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID)
                                    VALUES (P_ITEM_ID,SYSDATE,P_ORGANIZATION_ID,'03','04',PR_LINE_ID,PR_HEADER_ID);
    END IF;

    /* Assinging the cuenta should be changed based on the item types */
    IF (T_ATTRIBUTE1 = '01' )  THEN
       T_CHANGE_SEGMENT := T_SEGMENT4;
       --23.Ene.2007 Extend the values for attribute2
    ELSIF (T_ATTRIBUTE1 = '04' AND ( T_ATTRIBUTE2 = 'N/A' OR T_COUNT_GPOTOTAL > 0) AND T_FLAG = 'N') THEN
       T_CHANGE_SEGMENT := T_ATTRIBUTE3;
    END IF;

    IF (T_ATTRIBUTE1 = '01' AND T_ATTRIBUTE7 != 'KIT')  THEN
        -- Inicia CHO 51413405
        IF T_Change_Segment = '26AC0025' THEN
           T_New_Segment4 := '26AC0025' ;
        ELSE
           T_New_Segment4 := '72IF'||SUBSTR(T_Change_Segment,5,4);
        END IF;
        -- Fin CHO 51413405

    ELSIF (T_ATTRIBUTE1 = '01' AND T_ATTRIBUTE7 = 'KIT') THEN
        T_NEW_SEGMENT4 := '72IF1162';
--  JP feb_06
---    T_NEW_SEGMENT4 := T_ATTRIBUTE3;
----
    ELSIF (T_ATTRIBUTE1 = '04' AND LTRIM(RTRIM(T_ATTRIBUTE2)) IN('N/A') AND T_FLAG = 'N') THEN
        T_NEW_SEGMENT4 := T_CHANGE_SEGMENT;
        --23.Ene.2007 Extend the values for attribute2
    ELSIF (T_ATTRIBUTE1 = '04' AND T_COUNT_GPOTOTAL > 0 AND T_FLAG = 'N') THEN
       BEGIN
          SELECT ORACLE_CR_SUPERIOR INTO P_ORACLE_CR FROM XXFC_MAESTRO_DE_CRS_V
          WHERE ORACLE_CR = P_ORACLE_CR
          AND   ORACLE_EF = P_ORACLE_EF;
          EXCEPTION
          WHEN OTHERS THEN NULL;
       END;
       T_NEW_SEGMENT4 := T_CHANGE_SEGMENT;
       INSERT INTO XXINV_CHANGE_ITEM_ATTRIBUTE_KC(ITEM_ID,CHANGE_DATE,ORGANIZATION_ID,ORG_ATTRIBUTE1,CHANGE_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID)
              VALUES (P_ITEM_ID,SYSDATE,P_ORGANIZATION_ID,'04','04',PR_LINE_ID,PR_HEADER_ID);
              --23.Ene.2007 Extend the values for attribute2
    ELSIF  (T_ATTRIBUTE1 = '04' AND T_COUNT_GPOTOTAL > 0  AND T_FLAG = 'Y') THEN
       T_NEW_SEGMENT4 := '72IF1162';
       INSERT INTO XXINV_CHANGE_ITEM_ATTRIBUTE_KC(ITEM_ID,CHANGE_DATE,ORGANIZATION_ID,ORG_ATTRIBUTE1,CHANGE_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID)
              VALUES (P_ITEM_ID,SYSDATE,P_ORGANIZATION_ID,'04','03',PR_LINE_ID,PR_HEADER_ID);
    END IF;
--INICIA CHO 52008259
--ELSIF (TO_NUMBER(SUBSTR(P_ORACLE_CR,1,2)) BETWEEN 30 AND 31)  THEN
ELSIF (TO_NUMBER(SUBSTR(P_ORACLE_CR,1,2)) IN (30,31,43))  THEN
--FIN CHO 52008259
    IF (T_ATTRIBUTE1 ='01' ) THEN
     T_CHANGE_SEGMENT := T_SEGMENT4;
    END IF;
    IF (T_ATTRIBUTE1 = '01'  AND T_ATTRIBUTE7 != 'KIT') THEN
       T_NEW_SEGMENT4 := '73OR'||SUBSTR(T_CHANGE_SEGMENT,5,4);
    ELSIF (T_ATTRIBUTE1 = '01' AND T_ATTRIBUTE7 = 'KIT') THEN
       T_NEW_SEGMENT4 := '73OR1162';
    ELSIF T_ATTRIBUTE1 = '03' THEN
-- JP abr_03       T_NEW_SEGMENT4 := '73OR0877';
       T_NEW_SEGMENT4 := '73OR0874';
       INSERT INTO XXINV_CHANGE_ITEM_ATTRIBUTE_KC(ITEM_ID,CHANGE_DATE,ORGANIZATION_ID,ORG_ATTRIBUTE1,CHANGE_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID)
                  VALUES (P_ITEM_ID,SYSDATE,P_ORGANIZATION_ID,T_ATTRIBUTE1,'01',PR_LINE_ID,PR_HEADER_ID);
       --23.Ene.2007 Extend the values for attribute2
    ELSIF (T_ATTRIBUTE1 = '04' AND T_COUNT_GPOTOTAL > 0 ) THEN
       T_NEW_SEGMENT4 := '73OR1162';
--       INSERT INTO XXINV_CHANGE_ITEM_ATTRIBUTE(ITEM_ID,CHANGE_DATE,ORGANIZATION_ID,ORG_ATTRIBUTE1,CHANGE_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID)
--              VALUES (P_ITEM_ID,SYSDATE,P_ORGANIZATION_ID,'04','03',PR_LINE_ID,PR_HEADER_ID);
-- JP  ene-29
    INSERT INTO XXINV_CHANGE_ITEM_ATTRIBUTE_KC(ITEM_ID,CHANGE_DATE,ORGANIZATION_ID,ORG_ATTRIBUTE1,CHANGE_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID)
         VALUES (P_ITEM_ID,SYSDATE,P_ORGANIZATION_ID,T_ATTRIBUTE1,'01',PR_LINE_ID,PR_HEADER_ID);
    END IF;
--INICIA CHO 52008259
--ELSIF (TO_NUMBER(SUBSTR(P_ORACLE_CR,1,2)) BETWEEN 32 AND 49)  THEN
ELSIF ((TO_NUMBER(SUBSTR(P_ORACLE_CR,1,2)) BETWEEN 32 AND 42) OR (TO_NUMBER(SUBSTR(P_ORACLE_CR,1,2)) BETWEEN 44 AND 49))  THEN
--FIN CHO 52008259
    IF (T_ATTRIBUTE1 = '01') THEN
       T_CHANGE_SEGMENT := T_SEGMENT4;
    END IF;
    IF  (T_ATTRIBUTE1 = '01' AND T_ATTRIBUTE7 != 'KIT' ) THEN
        T_NEW_SEGMENT4 := '72SU'||SUBSTR(T_CHANGE_SEGMENT,5,4);
    ELSIF (T_ATTRIBUTE1 = '01' AND T_ATTRIBUTE7 = 'KIT') THEN
        T_NEW_SEGMENT4 := '72SU1162';
    ELSIF T_ATTRIBUTE1 = '03' THEN
--  JP abr_03      T_NEW_SEGMENT4 := '72SU0877';
        T_NEW_SEGMENT4 := '72SU0874';
        INSERT INTO XXINV_CHANGE_ITEM_ATTRIBUTE_KC(ITEM_ID,CHANGE_DATE,ORGANIZATION_ID,ORG_ATTRIBUTE1,CHANGE_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID)
                  VALUES (P_ITEM_ID,SYSDATE,P_ORGANIZATION_ID,T_ATTRIBUTE1,'01',PR_LINE_ID,PR_HEADER_ID);
        --23.Ene.2007 Extend the values for attribute2
    ELSIF (T_ATTRIBUTE1 = '04' AND T_COUNT_GPOTOTAL > 0 ) THEN
        T_NEW_SEGMENT4 := '72SU1162';
--         INSERT INTO XXINV_CHANGE_ITEM_ATTRIBUTE(ITEM_ID,CHANGE_DATE,ORGANIZATION_ID,ORG_ATTRIBUTE1,CHANGE_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID)
--                VALUES (P_ITEM_ID,SYSDATE,P_ORGANIZATION_ID,'04','03',PR_LINE_ID,PR_HEADER_ID);
-- JP  ene-29
           INSERT INTO XXINV_CHANGE_ITEM_ATTRIBUTE_KC(ITEM_ID,CHANGE_DATE,ORGANIZATION_ID,ORG_ATTRIBUTE1,CHANGE_ATTRIBUTE1,PR_LINE_ID,PR_HEADER_ID)
                  VALUES (P_ITEM_ID,SYSDATE,P_ORGANIZATION_ID,T_ATTRIBUTE1,'01',PR_LINE_ID,PR_HEADER_ID);
    END IF;
END IF;
P_CUENTA := T_NEW_SEGMENT4;
--FND_FILE.PUT_LINE(FND_FILE.LOG,'dbg:lmc p_cuenta: '||p_cuenta);
EXCEPTION
 WHEN OTHERS THEN
--   FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR OCCURS IN CHECK_ITEM_ACCOUNT DUE TO '||SQLERRM||' FOR ORACLE CR '||P_ORACLE_CR);
    T_PERIOD_NUM:=0;
END CHECK_ITEM_ACCOUNT;

PROCEDURE CREATE_CODE_COMBINATION(P_SEGMENT1 IN VARCHAR2,P_SEGMENT2 IN VARCHAR2,P_SEGMENT3 IN VARCHAR2,
          P_SEGMENT4 IN VARCHAR2,P_CODE_COMBINATION_ID OUT NUMBER,P_RET_CODE OUT VARCHAR2,
          P_ERR_BUF  OUT VARCHAR2) IS
T_CODE_COMBINATION_ID NUMBER;
T_RET_CODE NUMBER := 0;
w_cuenta2 NUMBER;
w_tipo_cuenta VARCHAR2(1);
-- JP 12.2.4.
ln_ChartOfAccountsId NUMBER;
--
BEGIN
   SELECT gl_code_combinations_s.nextval into T_CODE_COMBINATION_ID from dual;
   P_CODE_COMBINATION_ID := T_CODE_COMBINATION_ID;
   w_cuenta2 := TO_NUMBER(SUBSTR(p_segment4,1,2));
   IF w_cuenta2 <= 32 THEN
         w_tipo_cuenta := 'A';
   ELSIF w_cuenta2  BETWEEN 33 AND 47 THEN
         w_tipo_cuenta :='L' ;
   ELSIF w_cuenta2  BETWEEN 48 AND 49 THEN
         w_tipo_cuenta :='O';
   ELSIF w_cuenta2  BETWEEN 50 AND 61 THEN
         w_tipo_cuenta :='R';
   ELSIF w_cuenta2 > 61 THEN
         w_tipo_cuenta :='E';
   END IF;
-- JP 12.2.4
   SELECT chart_of_accounts_id
   INTO   ln_ChartOfAccountsId
   FROM   gl_ledgers
   WHERE  ledger_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
--
   INSERT INTO GL_CODE_COMBINATIONS(CODE_COMBINATION_ID,LAST_UPDATE_DATE ,LAST_UPDATED_BY ,
      CHART_OF_ACCOUNTS_ID,DETAIL_POSTING_ALLOWED_FLAG,DETAIL_BUDGETING_ALLOWED_FLAG,
      ACCOUNT_TYPE,ENABLED_FLAG,SUMMARY_FLAG,SEGMENT1,SEGMENT2,SEGMENT3,SEGMENT4,
      SEGMENT5,SEGMENT6,SEGMENT7)
-- JP 12.2.4   VALUES(T_CODE_COMBINATION_ID,SYSDATE,FND_GLOBAL.USER_ID,50201,'Y','Y',w_tipo_cuenta,'Y','N',
   VALUES(T_CODE_COMBINATION_ID,SYSDATE,FND_GLOBAL.USER_ID,ln_ChartOfAccountsId,'Y','Y',w_tipo_cuenta,'Y','N',
-- JP 12.2.4   P_SEGMENT1,P_SEGMENT2,P_SEGMENT3,P_SEGMENT4,'00000000','000000','000');
   P_SEGMENT1,P_SEGMENT2,P_SEGMENT3,P_SEGMENT4,'00000000','000000','00000');

 EXCEPTION
WHEN OTHERS THEN
  P_RET_CODE := 1;
  P_ERR_BUF  := SQLERRM;
END CREATE_CODE_COMBINATION;


END;
/