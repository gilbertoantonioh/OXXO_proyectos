SET DEFINE OFF;
PROMPT PACKAGE SPEC XXFA_SN_DATA_API_PKG
CREATE OR REPLACE PACKAGE apps.xxfa_sn_data_api_pkg 
AS 

   /********************************************************************************************
   * Modulo : XXFA_SN_DATA_API_PKG
   * Autor : Gilberto Hernandez (Hexaware) 
   * Version : 1.0
   * Fecha : 15/Ago/2025
   * Descripcion : API para realizar cargas de informacion para la tabla xxfc.xxfa_sn_data_details
   *
   * Ejecutado Por :
   *
   * Ejecuciones :
   *
   * Modificado Por                 Fecha         Codigo          Descripcion
   * -------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0113888      Se complementan la tabla intermedia con nuevos atributos.
   * Gilberto Hernandez (Hexaware)  12/Sep/2025   CHG0113888      LLenar la tabla intermedia validacion fiscal xxfa_sn_fe_data_details para service now. 
   * Gilberto Hernandez (Hexaware)  11/Oct/2025   CHG0116809      Actualizar la tabla intermedia previo a la salida de pedido de movimiento
   * Gilberto Hernandez (Hexaware)  6/Dic/2025    CHG0135592      Cargar informacion de viajes para compartir a service now 
   ********************************************************************************************/

   /********************************************************************************************
   Modulo : load_details_from_rcv_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Carga informacion a la tabla intermedia desde la recepcion de inventario
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0113888      Se complementan la tabla intermedia con nuevos atributos.   
   ********************************************************************************************/
   PROCEDURE load_details_from_rcv_prc (  errbuf               OUT VARCHAR2
                                        , retcode              OUT VARCHAR2
                                        , p_rcv_transaction_id IN NUMBER
                                        );
	

   /********************************************************************************************
   Modulo : load_fe_details_from_rcv_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Carga informacion a la tabla intermedia desde la recepcion de inventario
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
   PROCEDURE load_fe_details_from_rcv_prc (  errbuf               OUT VARCHAR2
                                           , retcode              OUT VARCHAR2
                                           , p_rcv_transaction_id IN NUMBER
                                           );
                                           
   /********************************************************************************************
   Modulo : load_details_from_assets
   Autor : Samanta Solis (Hexaware)
   Fecha : 08/Oct/2025
   Descripcion : Carga informacion a la tabla intermedia desde el activo
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Samanta Solis (Hexaware)  08/Oct/2025      CHG0116809       Version Inicial
   ********************************************************************************************/
   PROCEDURE load_details_from_assets(  errbuf               OUT VARCHAR2
                                      , retcode              OUT VARCHAR2
                                      );
									  
   /********************************************************************************************
   Modulo : update_details_from_wsh_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 10/Oct/2025
   Descripcion : Actualizar informacion a la tabla intermedia desde previo a la salida del pedido de movimiento 
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  10/Oct/2025   CHG0116809      Version Inicial
   ********************************************************************************************/
   PROCEDURE update_details_from_wsh_prc(  errbuf               OUT VARCHAR2
                                         , retcode              OUT VARCHAR2
                                         , p_delivery_name       IN VARCHAR2
                                         , p_organization_id     IN NUMBER 
                                         );
										 
   /********************************************************************************************
   Modulo : upd_det_from_wsh_set_doc_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 10/Oct/2025
   Descripcion : Ejecutar proceso de actualizar informacion a la tabla intermedia desde previo a la salida del pedido de movimiento durante el Pick Release (Juego de Documentos de Envio WSH) 
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  10/Oct/2025   CHG0116809      Version Inicial
   ********************************************************************************************/ 
   PROCEDURE upd_det_from_wsh_set_doc_prc( errbuf               OUT VARCHAR2
                                         , retcode              OUT VARCHAR2
                                         , p_delivery_name       IN VARCHAR2
                                         , p_organization_id     IN NUMBER 
                                         );
										 
    /********************************************************************************************
   Modulo : load_trips_from_wsh_prc 
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 6/Dic/2025
   Descripcion : Carga informacion a la tabla de viajes para compartir a service now
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  6/Dic/2025   CHG0135592      Version Inicial
   ********************************************************************************************/
   PROCEDURE load_trips_from_wsh_prc (  errbuf               OUT VARCHAR2
                                      , retcode              OUT VARCHAR2
                                      , p_delivery_name       IN VARCHAR2
                                      , p_organization_id     IN NUMBER 
                                     );

   /********************************************************************************************
   Modulo : purge_trips_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Carga informacion a la tabla de viajes para compartir a service now
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135592      Version Inicial
   ********************************************************************************************/
   PROCEDURE purge_trips_prc ( errbuf               OUT VARCHAR2
                             , retcode              OUT VARCHAR2
                              )  ;
	
END xxfa_sn_data_api_pkg;
/
SHOW ERRORS;