SET DEFINE OFF;
PROMPT PACKAGE SPEC XXFA_SN_PO_OTH_VALIDATE_PKG
CREATE OR REPLACE PACKAGE apps.xxfa_sn_po_oth_validate_pkg 
AS 

   /********************************************************************************************
   * Modulo : XXFA_SN_PO_OTH_VALIDATE_PKG
   * Autor : Gilberto Hernandez (Hexaware) 
   * Version : 1.0
   * Fecha : 7/Abril/2025
   * Descripcion : Paquete para realizar las validaciones sobre otras compras de Activo Fijo como Cargos Directos o Virtuales, para confirmar que los datos
   *               son correctos para el flujo de EBS a Service Now. 
   *
   * Ejecutado Por :
   *
   * Ejecuciones :
   *
   * Modificado Por                 Fecha         Codigo          Descripcion
   * -------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  7/Abril/2025  CHG0145709      Version Inicial
   ********************************************************************************************/
   
   /********************************************************************************************
   Modulo : is_use_item_for_cd_fnc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 9/Abril/2025
   Descripcion : Valida si el uso del articulo es para para el proceso de Cargos Directos 
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  9/Abril/2025  CHG0145709      Version Inicial
   ********************************************************************************************/
   FUNCTION is_use_item_for_cd_fnc (pv_use_item IN VARCHAR2) 
   RETURN VARCHAR2
   ;
   
   /********************************************************************************************
   Modulo : cd_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 7/Abril/2025
   Descripcion : Validar datos para compras de Activo Fijo de tipo Cargos Directos 
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  7/Abril/2025  CHG0145709      Version Inicial
   ********************************************************************************************/
   PROCEDURE cd_prc (  errbuf               OUT VARCHAR2
                     , retcode              OUT VARCHAR2
                     , p_po_header_id        IN NUMBER
                     , p_po_release_id       IN NUMBER
                     );
    
END xxfa_sn_po_oth_validate_pkg;
/
SHOW ERRORS;