--Select *  from APPS.FA_MASS_ADDITIONS
Delete from APPS.FA_MASS_ADDITIONS
where create_batch_date = '13-NOV-2024'
AND FEEDER_SYSTEM_NAME ='ALMACEN';

-- Validar los siguientes deletes
-----------------------------------------
DELETE FROM XXINV_PRE_MATERIAL_TRX_TEMP;


DELETE FROM XXINV_MATERIAL_TRX_TEMP;
-----------------------------------------


select *
from XXINV_CTRL_FA_MASS_ADDITIONS


DELETE FROM xxfc.XXINV_CTRL_FA_MASS_ADDITIONS
WHERE  TRUNC (creation_date) = '13-NOV-2024';
--truncate table xxfc.XXINV_CTRL_FA_MASS_ADDITIONS


-- nnn  Filas

--SELECT * FROM   apps.xxinv_issue_fixed_asset_web
DELETE FROM   apps.xxinv_issue_fixed_asset_web
WHERE    TRUNC (creation_date) = '13-NOV-2024';

--nnn  Filas

-- Revisar 
--SELECT * FROM apps.XXINV_CHANGE_ITEM_ATTRIBUTE_KC
DELETE FROM apps.XXINV_CHANGE_ITEM_ATTRIBUTE_KC
WHERE trunc(CHANGE_DATE)  between  '10-NOV-2024' and '17-NOV-2024';

--nnn  Filas
/* Para depurar la informacion historica
DELETE FROM apps.XXINV_CHANGE_ITEM_ATTRIBUTE_KC
WHERE trunc(CHANGE_DATE) < '01-JUL-2024'
*/

--SELECT * FROM XXFC.XXINV_KIT_ITEMS_DIARIO
DELETE FROM XXFC.XXINV_KIT_ITEMS_DIARIO
WHERE TRUNC(CREATION_DATE) = '13-NOV-2024';
--order by creation_date;

--nnn  Filas


UPDATE  apps.mtl_material_transactions 
        SET  attribute10          =  'R12 Upg'
               ,attribute11          =  '13-NOV-2024'
               ,attribute14          =  'R12 Upg'
               ,attribute15          =  '20240221999'
--SELECT * FROM  apps.mtl_material_transactions 
WHERE  trunc(creation_date) = '13-NOV-2024'
AND   transaction_type_id = 33 --33-change Sales order issue WMS 23-03-17
AND    transaction_action_id = 1
AND    transaction_source_type_id = 2 --2-change Sales order issue WMS 23-03-17
AND    organization_id           =   93
AND    actual_cost IS NOT NULL ;

--nnn  Filas 

--SELECT * FROM apps.xxinv_material_transactions
DELETE FROM apps.xxinv_material_transactions
WHERE TRUNC(MMT_CREATION_DATE) =  '13-NOV-2024';


select *
from apps.xxinv_material_transactions
--nnn  Filas

select *
from xxfc_sn_escaneo_lineas


update xxfc_sn_escaneo_lineas
set sts_header_id = null
, STS_LINE_ID = NULL;



commit;

XXINV: Creacion de transacciones contables en resumen
XXINV: Creacion de polizas en interfases de GL
XXINV: Creacion de movs para cartas interempresas
XXINV: Creacion de cartas interempresas (OL4)
XXINV: Creacion de movs de salida  legacy (OL3)



-- Query para ver el resultado en el modulo de activos fijos
SELECT fma.mass_addition_id, 
       fma.description, 
       fma.serial_number, -- model
       TRUNC(fma.create_batch_date) fecha,
       fma.feeder_system_name origen,
       ROUND(fma.fixed_assets_cost, 2) costo,
       invoice_number num_salida,
       attribute7, 
       attribute8
FROM apps.fa_mass_additions fma
WHERE fma.create_batch_date >= '10-DEC-2024'
  AND fma.feeder_system_name = 'ALMACEN'
ORDER BY 1 DESC;