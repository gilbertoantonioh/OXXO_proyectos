53477109
43777961
43568406
41649881
45647423
45647425
45647427
45647415
45647411
45647407
45647409
45647413
45647403
44850881
44850889
44850885
44850617
45730013
45617565
28983945
33915429
53475121
51819831
24023331


select *
from apps.xxfc_mapeos_varios
where tipo_mapeo = 'XXFA_EBS_SN'
and entrada = 'EBS_SN_FE';


DECLARE
  l_return_status VARCHAR2 (1000);
  l_msg_data      VARCHAR2 (1000);
  CURSOR c1
  IS
    SELECT *
    FROM po_headers_all
    WHERE segment1            IN ('2414767' )
    AND  ORG_ID = 85
    AND type_lookup_code       = 'STANDARD'
    AND (authorization_status != 'APPROVED'
    OR authorization_status   IS NULL );
    
BEGIN
 --  mo_global.init ('PO');
   fnd_global.apps_initialize (9600, 54802, 201);
  
   FOR i IN c1
   LOOP
      po_document_action_pvt.do_approve (p_document_id      => i.po_header_id, 
                                         p_document_type    => 'PO', 
                                         p_document_subtype => 'STANDARD', 
                                         p_note             => '– Your comments that need TO be displayed IN action History', 
                                         p_approval_path_id => 62, 
                                         x_return_status    => l_return_status, 
                                         x_exception_msg    => l_msg_data 
                                         );
      DBMS_OUTPUT.put_line (l_return_status);
      COMMIT;
   END LOOP;
END;


XXFC.XXFC_CARGO_CENTRAL_HEADERS
XXFC.XXFC_CARGO_CENTRAL_LINES
	Se tiene un campo, solicitud inversion legacy (se maneja en la tabla de requiciones en el attr1)


XXINV_ITEM_FIXED_ASSET_WEB_PKG Paquete que crea los activos fijos del almacen.
XXPO_RECEIPT_AP_INVOICE_PKG Paquete que crea las facturas de la recepcion de Almacen


xxfc_cargo_central_puestos


xxfc_cve_activo_ctas

select *
from xxfc_cve_activo_ctas;

select *
from mtl_system_items_b a
where a.attribute2 in  (select b.articulo_id from xxfc_cve_activo_ctas b)
and a.organization_id = 93;

XXFC_CARGO_CENTRAL_PUESTOS






select b.*
from   XXFC_CARGO_CENTRAL_LINES a
     , po_requisition_headers_all b
where a.inversion_num = b.attribute1
order by b.creation_date desc     


select *
from po_requisition_lines_all
where requisition_header_id = 16915500
;


select *
from  po_req_distributions_All
where requisition_line_id = 23558678
;

select *
from po_distributions_All
where req_distribution_id = 20247453;


select *
from po_headers_all
where po_header_id = 15384699;




XXFC_CARGO_CENTRAL_PKG
Principal
Inserta_Cargos_Centrales_Fnc

--LLAMA CREACIoN DE DOCUMENTOS
XXFC_CARGO_CENTRAL_PKG.Carta_Femsa;
XXFC_CARGO_CENTRAL_PKG.Factura_AP;
XXFC_CARGO_CENTRAL_PKG.Conta_GL;
XXFC_CARGO_CENTRAL_PKG.Registro_Activo;
XXFC_CARGO_CENTRAL_PKG.Conta_Legacy;
Actualiza_Facturas_CC;




xxfc_xp_cargo_central_headers
xxfc_xp_cargo_central_lines




XXFC-Captura Cargos Centrales			XXFCCFCC.fmb

RG_PROVEEDORES
SELECT   aps.vendor_id
        ,aps.vendor_name
         ,aps.segment1
FROM     apps.ap_suppliers aps
WHERE    NVL(aps.end_date_active, SYSDATE+1)  > SYSDATE
AND       aps.vendor_type_lookup_code IN('ACTIVO FIJO','ACTIVO FIJO-TERRENOS'
                                       ,'VENDOR', 'PRESTADORES DE SERVICIO' 
                                       ,'FLETEROS', 'FILIALES')                                                                              
AND      aps.vendor_id IN (SELECT   apssa.vendor_id
                          FROM     apps.ap_supplier_sites_all apssa,
                                  (SELECT tax_rate,name,set_of_books_id,tax_type
                                     FROM  apps.ap_tax_codes_all
                                     WHERE 
                                           enabled_flag    = 'Y'
                                     AND   set_of_books_id         = fnd_profile.VALUE('GL_SET_OF_BKS_ID')
 
 
RG_ARTICULOS

SELECT   ffvv.flex_value
        ,ffvv.flex_value_meaning
        ,ffvv.description
FROM     apps.fnd_flex_values_vl    ffvv_parent
                                  ,apps.fnd_flex_value_sets   ffvs_parent
                                  ,apps.fnd_flex_value_sets   ffvs
                                  ,apps.fnd_flex_values_vl    ffvv
WHERE    ffvv_parent.flex_value_set_id    = ffvs_parent.flex_value_set_id
AND      UPPER(ffvv_parent.description)   LIKE 'ACTIVO%FIJO%'
AND      ffvs_parent.flex_value_set_name  = 'XXINV_TIPO_DE_USO'
AND      ffvs.parent_flex_value_set_id    = ffvs_parent.flex_value_set_id
AND      ffvs.flex_value_set_name         = 'XXINV_AF_CLAVES'
AND      ffvv.flex_value_set_id           = ffvs.flex_value_set_id
AND      ffvv.parent_flex_value_low       = ffvv_parent.flex_value
AND      ffvv.flex_value IN (SELECT articulo_id
                             FROM   apps.xxfc_cve_activo_ctas
                            )
ORDER BY ffvv.flex_value
 
 
 
SELECT DISTINCT 
       cch.header_id
     , cch.org_id AS cch_org_id
     , cch.vendor_id
     , cch.vendor_site_id
     , cch.invoice_num
     , ccl.line_id 
     , ccl.org_id AS ccl_org_id
     , ccl.oracle_ef
     , ccl.oracle_cr
     , ccl.inversion_num 
     , prh.requisition_header_id
     , prh.segment1 AS requisition_number 
     , prh.creation_date
     , prh.description
     , ccl.articulo_id
     , msi.inventory_item_id 
     , msi.description AS item_description 
FROM  apps.xxfc_cargo_central_headers cch
    , apps.xxfc_cargo_central_lines ccl
    , apps.po_requisition_headers_all prh
    , apps.mtl_system_items_b msi 
WHERE cch.header_id      = ccl.header_id 
AND   ccl.inversion_num  = prh.attribute1
AND   ccl.articulo_id    = msi.attribute2 
ORDER BY requisition_number
;


SELECT DISTINCT 
       cch.header_id
     , cch.org_id AS cch_org_id
     , cch.vendor_id
     , cch.vendor_site_id
     , cch.invoice_num
     , ccl.line_id 
     , ccl.org_id AS ccl_org_id
     , ccl.oracle_ef
     , ccl.oracle_cr
     , ccl.inversion_num 
     , prh.requisition_header_id
     , prh.segment1 AS requisition_number 
     , prh.creation_date
     , prh.description
     , ccl.articulo_id
FROM  apps.xxfc_cargo_central_headers cch
    , apps.xxfc_cargo_central_lines ccl
    , apps.po_requisition_headers_all prh
WHERE cch.header_id      = ccl.header_id 
AND   ccl.inversion_num  = prh.attribute1 
ORDER BY requisition_number
;
 

SELECT  concatenated_segments, alias_name
FROM    apps.fnd_shorthand_flex_aliases
WHERE   id_flex_code = 'CAT#'
and alias_name = 'V.16'
;


select *
from apps.xxfc_cve_activo_ctas;


SELECT  c.category_id    l_category_id
FROM    apps.fa_categories c
WHERE   c.segment1 || '.' || c.segment2 || '.' || c.segment3 || '.' || c.segment4 = 'ME.45.010.V16'
 ;


SELECT  description    l_description_cat
FROM    apps.fa_categories
WHERE   category_id = 2850
; 



SELECT  fsa.alias_name
      , fca.category_id
      , fca.description
      , fca.segment1
      , fca.segment2
FROM    apps.fnd_shorthand_flex_aliases fsa
      , apps.fa_categories fca 
WHERE   fsa.id_flex_code = 'CAT#'
AND     fsa.concatenated_segments = fca.segment1 || '.' || fca.segment2 || '.' || fca.segment3 || '.' || fca.segment4 
AND     fca.enabled_flag = 'Y'  
ORDER BY 1 



where 1=1 and nvl(enabled_flag,'Y')='Y'
  and flex_value_set_id=(select flex_value_set_id from FND_FLEX_VALUE_SETS where FLEX_VALUE_SET_NAME ='XXINV_TIPO_DE_USO')
  and instr(
  (Select description from fnd_flex_values_vl
  where 1=1 
  and nvl(enabled_flag,'Y')='Y'
  and flex_value_set_id=(select flex_value_set_id from FND_FLEX_VALUE_SETS where FLEX_VALUE_SET_NAME = 'XXFC_INV_ADD_TIPOS_DE_USO')
  and flex_value=:$PROFILES$.USERNAME),flex_value)>0
  
  
  


SELECT DISTINCT msi.attribute1 
FROM   apps.po_headers_all poh
     , apps.po_lines_all pol
     , apps.mtl_system_items_b msi
WHERE poh.po_header_id = pol.po_header_id 
AND   pol.item_id      = msi.inventory_item_id
AND   poh.segment1 IN 
(
 '2416449'
,'2416745'
,'2416747'
,'2417007'
,'2417008'
,'2417093'
,'2417114'
,'2417134'
,'2417136'
,'2417374'
,'2417373'
,'2417283'
,'2417496'
,'2417159'
,'2415196'
,'2415691'
,'2416262'
,'2416413'
,'2416514'
,'2416630'
,'2417109'
,'2417120'
,'2417121'
,'2417122'
,'2417124'
,'2416233'
,'2417295'
,'2417105'
,'275677'
,'274888'
,'274432'
,'49807'
,'49836'
,'49757'
,'49909'
,'48750'
,'49165'
,'49039'
,'285439'
,'2416980'
,'2416908'
,'2417034'
,'2417035'
,'2417036'
,'2416979'
,'2417499'
,'2417503'
,'2417500'
,'2416893'
,'2417557'
,'264420'
,'263496'
,'264095'
,'264096'
,'263701'
,'49134'
,'49375'
,'49091'
,'47770'
,'267438'
,'49621'
,'49409'
,'266427'
,'49661'
,'49201'
,'48940'
,'49641'
,'48156'
,'271117'
,'49090'
,'49656'
,'49936'
,'265543'
,'274419'
,'266031'
,'49194'
,'269282'
,'2417115'
,'2417117'
,'2417521'
,'2417520'
)



select descriptive_flexfield_name,application_column_name, end_user_column_name, enabled_flag, display_flag
from  apps.fND_DESCR_FLEX_COL_USAGE_VL 
where descriptive_flexfield_name = 'MTL_SYSTEM_ITEMS'
order by application_column_name;



from  apps.fa_mass_additions;
feeder_system_name, property_type_code	
ORACLE	
ALMACEN				ALMACEN
					DIRECTOS
					MANUAL
					MASIVA
					MAS_POLIZA
					INICIAL
					ALMACEN
DIRECTOS			DIRECTOS
ORACLE				MAS_POLIZA
ORACLE				MASIVA



DIRECTOS
MANUAL
MASIVA
MAS_POLIZA
TRASPASO
INICIAL
HANDHELD
ALMACEN


from apps.fa_additions;
property_type_code
DIRECTOS
MANUAL
MASIVA
MAS_POLIZA
TRASPASO
INICIAL
HANDHELD
ALMACEN


flex value set: FA_PROPERTY_TYPE
lookup type: PROPERTY TYPE



select *
from apps.FA_LOOKUPS
WHERE
LOOKUP_TYPE='PROPERTY TYPE'
ORDER BY DESCRIPTION;





where 1=1 and nvl(enabled_flag,'Y')='Y'
  and flex_value_set_id=(select flex_value_set_id from FND_FLEX_VALUE_SETS where FLEX_VALUE_SET_NAME ='XXINV_TIPO_DE_USO')
  and instr(
  (Select description from fnd_flex_values_vl
  where 1=1 
  and nvl(enabled_flag,'Y')='Y'
  and flex_value_set_id=(select flex_value_set_id from FND_FLEX_VALUE_SETS where FLEX_VALUE_SET_NAME = 'XXFC_INV_ADD_TIPOS_DE_USO')
  and flex_value=:$PROFILES$.USERNAME),flex_value)>0
