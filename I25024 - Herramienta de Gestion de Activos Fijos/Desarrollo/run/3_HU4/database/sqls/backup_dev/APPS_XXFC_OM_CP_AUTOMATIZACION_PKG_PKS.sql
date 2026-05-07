CREATE OR REPLACE PACKAGE  XXFC_OM_CP_AUTOMATIZACION_PKG
IS
   /***************************************************************************************
   # Modulo        : XXFC_OM_CP_AUTOMATIZACION_PKG
   # Autor         : Samanta Solis
   # Versión       : 1.0
   # Fecha         : 28-Agosto-2023
   # Descripción   : Ejecuta el concurrente "XXFC-Carta Porte Almacen AF – Tienda" recibiendo el numero de viaje 
   #                 y "XXFC-Carta Porte Recolección Salidas Virtuales"
   #
   # Ejecutado Por : 
   #
   # Ejecuciones   : 
   #
   # Modificado Por         Fecha         Descripcion
   # -------------------------------------------------------------------------------------
   # Samanta Solis          28/Ago/2023   CHG0037801 Creacion de paquete
   # Samanta Solis          07/Jul/2022   CHG0046621 1) Se agrega parametro para validar estatus de la ejecucion 
                                                     del concurrente Generación de Lista de Selección
                                                     2) Se elimina validacion de despacho del pedido
   ***************************************************************************************/

   /********************************************************************************************
   Modulo      : inicio_prc
   Autor       : Samanta Solis
   Fecha       : 28-Agosto-2023
   Descripcion : Ejecuta el concurrente XXFC-Carta Porte Almacen AF – Tienda 
   
   Modificado Por       Fecha          Descripcion
   --------------------------------------------------------------------------------------------
   Samanta Solis      28/Ago/2023    CHG0037801 Creacion de paquete
   Samanta Solis      12/Ago/2024    CHG0046621 1) Se agrega parametro para validar estatus de la ejecucion 
                                                del concurrente Generación de Lista de Selección
                                                2) Se elimina validacion de despacho del pedido   
   ********************************************************************************************/
   PROCEDURE inicio_prc ( xv_Errbuf   OUT VARCHAR2
                        , xv_Retcode  OUT VARCHAR2
                        , pv_no_viaje IN  VARCHAR2
                        , pn_org_id   IN  NUMBER
                         );
   /********************************************************************************************
   Modulo      : ejecuta_concurrente_prc
   Autor       : Samanta Solis
   Fecha       : 28-Agosto-2023
   Descripcion : Ejecuta el concurrente XXFC-Carta Porte Automatizacion
   
   Modificado Por       Fecha          Descripcion
   --------------------------------------------------------------------------------------------
   Samanta Solis      28/Ago/2023    CHG0037801 Creacion de procedimiento
   ********************************************************************************************/
   PROCEDURE ejecuta_concurrente_prc( pv_application IN  VARCHAR2
                                    , pv_program     IN  VARCHAR2
                                    , pv_argument1   IN  VARCHAR2
                                    , pv_argument2   IN  VARCHAR2
                                    , pv_argument3   IN  VARCHAR2
                                    , pv_argument4   IN  VARCHAR2
                                    , pv_argument5   IN  VARCHAR2
                                    , pv_argument6   IN  VARCHAR2
                                    , pv_argument7   IN  VARCHAR2
                                    , pv_argument8   IN  VARCHAR2
                                    , pv_argument9   IN  VARCHAR2
                                    , pv_argument10  IN  VARCHAR2
                                    , pv_argument11  IN  VARCHAR2
                                    , pn_user_id     IN  NUMBER
                                    , pn_resp_id     IN  NUMBER
                                    , pn_app_id      IN  NUMBER
                                    , pn_req_id      OUT NUMBER);
									
   /********************************************************************************************
   Modulo      : obtiene_juego_valores_fnc
   Autor       : Samanta Solis
   Fecha       : 28-Agosto-2023
   Descripcion : Obtiene juego de valores
   
   Modificado Por       Fecha          Descripcion
   --------------------------------------------------------------------------------------------
   Samanta Solis      28/Ago/2023    CHG0037801 Creacion de funcion
   ********************************************************************************************/
   FUNCTION obtiene_juego_valores_fnc( pv_set_name    IN  VARCHAR2
                                     , pv_flex_value  IN  VARCHAR2
                                     )
   RETURN VARCHAR2;
   
END XXFC_OM_CP_AUTOMATIZACION_PKG;
/
SHOW ERRORS;