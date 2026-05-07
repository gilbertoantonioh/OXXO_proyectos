SET DEFINE OFF;
PROMPT TRIGGER XXFA_WSH_TRIPS_SN_AI ON WSH.WSH_TRIPS#
CREATE OR REPLACE TRIGGER APPS.XXFA_WSH_TRIPS_SN_AI
AFTER INSERT 
ON "WSH"."WSH_TRIPS#" 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
   /********************************************************************************************
   * Modulo : XXFA_WSH_TRIPS_SN_AI
   * Autor : Gilberto Hernandez (Hexaware) 
   * Version : 1.0
   * Fecha : 11/Dic/2025
   * Descripcion : Trigger para ejecutar el programa concurrente XXFA - SN Actualiza Informacion de Viajes WSH al momento de la creacion del viaje
   *
   * Ejecutado Por :
   *
   * Ejecuciones :
   *
   * Modificado Por                 Fecha         Codigo          Descripcion
   * -------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  11/Dic/2025   CHG0135592      Version Inicial
   ********************************************************************************************/
DECLARE
   ln_req_id      NUMBER;
   
   PRAGMA AUTONOMOUS_TRANSACTION;   
BEGIN
   -- Ejecutar el programa XXFA - SN Actualiza Informacion de Viajes WSH enviando el viaje como parametro 
   ln_req_id := apps.fnd_request.submit_request ( application  =>  'XXFC'
                                                , program      =>  'XXFA_SN_WSH_TRIPS'
                                                , description  =>  NULL
                                                , start_time   =>  NULL
                                                , sub_request  =>  FALSE
                                                , argument1    =>  :new.name
                                                , argument2    =>  NULL
                                                );

   COMMIT; 
EXCEPTION
   WHEN OTHERS THEN
      -- En caso de alguna falla no levantar ninguna excepcion 
	  NULL;
END;
/
SHOW ERRORS;