create or replace FUNCTION      Xxfc_Valida_Solinv (p_Org_Id        IN    NUMBER
                                              ,p_Header_Id     IN    NUMBER
		                                        ,p_Mensaje       OUT   VARCHAR2
															 ,p_Tipo          IN    NUMBER
															 ) RETURN BOOLEAN IS
	/* *************************************************************************
	# Author        : Andrea Garcia Rosas (TowaSoftware)
	# Curr VERSION  : 1.0
	# DATE          : 06-Marzo-2007.
	# Description   : Ingresa datos en tabla interfase para WebMethos y espera
	#                 el resultado de la validacion de la informacion
	# Inputs        : p_Header_Id   Id de la Factura de Cargos Centrales
	#                 p_Mensaje:  Mensaje informativo del resultado de la validacion
	# Called BY     : Pantalla de Captura de Facturas de Cargos Centrales
	# Calls
	# Modified BY     DATE        Description
	# --------------------------------------------------------------------------
	# AGR             22.05.2007  En XXFC_CARGO_CENTRAL_LINES la Solicitud de Inversi
                                 vienen separada por comas en el mismo campo, se deben
                                 insertar varios registros separando las solicitudes Inv.
   # Obed Torruco    24-JUL-24   CHG0041613_9 Se cambia el cálculo de segundos pasados para evitar un ciclo sin fin
   #                             en los segundos del 30 al 59. Se usa mejor una resta de fechas y conversion a segundos.
   #                             Se cambia el numero de CHO CHG0041613 por CHG0058490_1
   # Daniel Arciniega24-JUN-2025 Se cambia por este CHG para continuar con ultima version se sustituye
   #                             CHO CHG0058490_1 por CHG0065387
   # *************************************************************************/
	--
   CURSOR cur_SolInv_CC IS
	   SELECT xxfc_ccl.header_id
		      ,xxfc_ccl.Inversion_Num                                       Solicitud_Inversion
				,ROUND(((SUM(NVL(xxfc_ccl.atributo1, 0))) +
				        (SUM(xxfc_ccl.costo_unitario) + SUM(NVL(varios, 0))
						  ) * ( (xxfc_ccl.tax_rate/100)+1)
						 ), 2)                                                  Costo_Total
				,TRUNC(xxfc_ccl.creation_date)                                Creation_Date
				,xxfc_cch.invoice_num                                         Invoice_Num
				,xxfc_cch.atributo1                                           Divisa
				,xxfc_cch.atributo2                                           Tipo_Cambio
		FROM   xxfc_cargo_central_Headers xxfc_cch
		      ,xxfc_cargo_central_Lines   xxfc_ccl
		WHERE  xxfc_cch.org_id    = xxfc_ccl.org_id
		AND    xxfc_cch.Header_Id = xxfc_ccl.header_Id
		AND    xxfc_ccl.header_id = p_Header_Id
		AND    xxfc_ccl.org_id    = p_Org_Id
		AND    xxfc_ccl.Inversion_Num IS NOT NULL
		GROUP BY xxfc_ccl.header_id
		        ,xxfc_cch.invoice_num
		        ,xxfc_ccl.Inversion_Num
				  ,TRUNC(xxfc_ccl.creation_date)
				  ,xxfc_ccl.tax_rate
				  ,xxfc_cch.atributo1
				  ,xxfc_cch.atributo2;
   CURSOR cur_SolInv_WM IS
	   SELECT  invoice_id
		       ,si_number
				 ,total_amount
				 ,creation_date
				 ,wm_sent_date
				 ,wm_run_id
				 ,wm_status_val   wm_status_val
				 ,NVL(wm_status_exec, 'X') wm_status_exec
				 ,status_actualizacion
		FROM    xxfc_solinv_cargocen
      WHERE   invoice_Id = p_Header_Id;
   CURSOR cur_URL IS
      SELECT url
		      ,username
				,passwd
        FROM  wm_ol6_config;

	--
   v_Count_CC                 NUMBER      DEFAULT 0;
	v_Count_WM                 NUMBER      DEFAULT 0;
	v_Estado                   CHAR(2); -- "VA" NO HAY SALDO DISPONIBLE; "VF" ERROR AL VERIFICAR SALDO DISPONIBLE;
							  		             -- "ES" SALDO ACTUALIZADO;  EF ERROR AL ACTUALIZAR SALDO; "AS" VALIDADO Y ACTUALIZADO.
	v_Sol_Inversion            VARCHAR2(500) ;
	v_URL_WB                   NUMBER(1)   DEFAULT 2;
	v_Grupo                    NUMBER      DEFAULT 0;
	v_Set_Bks_id               NUMBER(5)   := Fnd_Profile.VALUE('GL_SET_OF_BKS_ID');
	v_Moneda_Funcional         VARCHAR2(3);
	v_Monto                    NUMBER;
	--v_Segundos                 NUMBER(3); CHG0041613_9
   v_Hora_Inicio              DATE; --CHG0041613_9
	--
	--FUNCION PARA IDENTIFICAR EL NUMERO DE COMAS QUE HAY EN LA SOLICITUD DE INVERSION
	--
	FUNCTION Count_Comas (p_Cadena   IN   VARCHAR2)
	                     RETURN NUMBER IS
	   v_Contador   NUMBER(3)    DEFAULT 0;
	BEGIN
	   FOR i IN 1..LENGTH(p_Cadena) LOOP
	      IF SUBSTR(p_Cadena, i, 1) =  ',' THEN
		      v_Contador := v_Contador + 1;
		   END IF;
	   END LOOP;
	   RETURN v_Contador;
	END Count_Comas;
	--
BEGIN
fnd_file.put_line(fnd_file.log,p_Header_id);
   --
	--OBTIENE LA MONEDA
	--
	SELECT   currency_code
   INTO     v_Moneda_Funcional
	FROM     gl_sets_of_books_v
	WHERE    set_of_books_id = v_Set_Bks_id;
   --
	--ELIMINA LOS REGISTROS QUE QUEDARON CON ERROR PARA LA FACTURA A PROCESAR O QUE YA FUERON CANCELADOS
	--
	DELETE xxfc_solinv_cargocen
	WHERE  invoice_id     = p_Header_Id
	AND    ((wm_status_val  <> 'A' AND    wm_status_exec <> 'S')
		        OR Total_Amount <= 0);
	--
   --IDENTIFICAR SI ES CANCELACION O VALIDACION
	--
   IF p_Tipo = -1 THEN
	   --CANCELA
		UPDATE xxfc_solinv_cargocen Act
		SET    Act.total_amount   = (SELECT qty_affected * p_Tipo
		                             FROM   xxfc_solinv_cargocen Cons
									        WHERE  Cons.Invoice_Id = Act.Invoice_Id
									        AND    Cons.SI_Number  = Act.SI_Number
									        AND    Cons.Grupo      = Act.Grupo
									      )
		      ,Act.WM_Status_Val  = 'L'
				,Act.WM_Status_Exec = NULL
		WHERE  Act.Invoice_Id      = p_Header_Id
		AND    Act.WM_Status_Val   = 'A'
		AND    Act.WM_Status_Exec  = 'S';
		v_Count_CC := SQL%ROWCOUNT;
	ELSE
	   --VALIDA
		--
		--INSERTA DATOS EN LA TABLA INTERFASE CON WEBMETHOS.
		--
		FOR reg_SolInv_CC IN cur_SolInv_CC LOOP
      fnd_file.put_line(fnd_file.log,'Entra loop Xxfc_Valida_Solinv');
		   --
			--Monto en Moneda Funcional
			--
			IF v_Moneda_Funcional <> reg_SolInv_CC.Divisa THEN
			   v_Monto := (((reg_SolInv_CC.Costo_Total)/1000) * reg_SolInv_CC.Tipo_Cambio);
			ELSIF v_Moneda_Funcional = reg_SolInv_CC.Divisa THEN
			   v_Monto := ((reg_SolInv_CC.Costo_Total)/1000);
			END IF;
			--
	      IF Count_Comas(reg_SolInv_CC.Solicitud_Inversion) = 0 THEN
			   v_Count_CC := v_Count_CC + 1;
			   v_Grupo    := cur_SolInv_CC%ROWCOUNT;
		      --SOLO HAY UNA SOLICITUD DE INSERVION EN EL CAMPO
				INSERT INTO xxfc.xxfc_solinv_cargocen (invoice_id
				                                 ,si_number
															,total_amount
															,creation_date
															,wm_sent_date
															,wm_run_id
															,wm_status_val
															,wm_status_exec
															,status_actualizacion
															,grupo
															,qty_affected
															,invoice_number
														   )
		      VALUES (reg_SolInv_CC.Header_Id
				       ,reg_SolInv_CC.Solicitud_Inversion
						 ,v_Monto
						 ,reg_SolInv_CC.creation_date
						 ,NULL
						 ,NULL
						 ,'L'
						 ,NULL
						 ,NULL
						 ,v_Grupo
						 ,NULL
						 ,reg_SolInv_CC.Invoice_Num
				       );
                   fnd_file.put_line(fnd_file.log,'Inserta 1');
		   ELSE
			   --HAY MAS DE UNA SOLICITUD DE INVERSION EN EL CAMPO
			   FOR i IN 1..Count_Comas(reg_SolInv_CC.Solicitud_Inversion) +1 LOOP
			      IF i = 1 THEN
					   v_Count_CC := v_Count_CC + 1;
					   v_Grupo    := cur_SolInv_CC%ROWCOUNT;
					   --PARA EL PRIMER VALOR
			         INSERT INTO xxfc_solinv_cargocen (invoice_id
				                                       ,si_number
															      ,total_amount
															      ,creation_date
															      ,wm_sent_date
															      ,wm_run_id
															      ,wm_status_val
															      ,wm_status_exec
															      ,status_actualizacion
															      ,grupo
															      ,qty_affected
															      ,invoice_number
														         )
		            VALUES (reg_SolInv_CC.Header_Id
				             ,SUBSTR(reg_SolInv_CC.Solicitud_Inversion, 1, INSTR(reg_SolInv_CC.Solicitud_Inversion, ',', 1,1)-1)
						       ,v_Monto
						       ,reg_SolInv_CC.creation_date
						       ,NULL
						       ,NULL
						       ,'L'
						       ,NULL
						       ,NULL
						       ,v_Grupo
						       ,NULL
						       ,reg_SolInv_CC.Invoice_Num
				             );
                         fnd_file.put_line(fnd_file.log,'Inserta 2');
			      ELSIF i = Count_Comas(reg_SolInv_CC.Solicitud_Inversion) +1 THEN
					   v_Count_CC := v_Count_CC + 1;
	   				v_Grupo    := cur_SolInv_CC%ROWCOUNT;
			         --PARA EL ULTIMO VALOR
			         INSERT INTO xxfc_solinv_cargocen (invoice_id
				                                       ,si_number
															      ,total_amount
															      ,creation_date
															      ,wm_sent_date
															      ,wm_run_id
															      ,wm_status_val
															      ,wm_status_exec
															      ,status_actualizacion
															      ,grupo
															      ,qty_affected
															      ,invoice_number
														         )
		            VALUES (reg_SolInv_CC.Header_Id
				             ,SUBSTR(reg_SolInv_CC.Solicitud_Inversion, INSTR(reg_SolInv_CC.Solicitud_Inversion, ',', 1,i-1)+1)
						       ,v_Monto
						       ,reg_SolInv_CC.creation_date
						       ,NULL
						       ,NULL
						       ,'L'
						       ,NULL
						       ,NULL
						       ,v_Grupo
						       ,NULL
						       ,reg_SolInv_CC.Invoice_Num
				             );
                         fnd_file.put_line(fnd_file.log,'Inserta 3');
			      ELSE
					   v_Count_CC := v_Count_CC + 1;
					   v_Grupo    := cur_SolInv_CC%ROWCOUNT;
					   --PARA LOS VALORRES MEDIOS
			         INSERT INTO xxfc_solinv_cargocen (invoice_id
				                                       ,si_number
															      ,total_amount
															      ,creation_date
															      ,wm_sent_date
															      ,wm_run_id
															      ,wm_status_val
															      ,wm_status_exec
															      ,status_actualizacion
															      ,grupo
															      ,qty_affected
															      ,invoice_number
														         )
		            VALUES (reg_SolInv_CC.Header_Id
				             ,SUBSTR(reg_SolInv_CC.Solicitud_Inversion, INSTR(reg_SolInv_CC.Solicitud_Inversion, ',', i,i-1)+1
						       ,INSTR(SUBSTR(reg_SolInv_CC.Solicitud_Inversion,INSTR(reg_SolInv_CC.Solicitud_Inversion, ',', i,i-1)+1),',',1) - 1)
						       ,v_Monto
						       ,reg_SolInv_CC.creation_date
						       ,NULL
						       ,NULL
						       ,'L'
						       ,NULL
						       ,NULL
						       ,v_Grupo
						       ,NULL
						       ,reg_SolInv_CC.Invoice_Num
				             );
                         fnd_file.put_line(fnd_file.log,'Inserta 4');
	            END IF;
	         END LOOP;
	      END IF;
	   END LOOP;
	END IF;
	--
	--SE GUARDAN LOS DATOS EN LA TABLA INTERFASE
	--
	COMMIT;
	--
	--OBTENER LOS DATOS PARA EJECUTAR EL PROCESO DE WEBMETHOS Y EJECUTARLO.
	--

	FOR reg_URL IN cur_URL LOOP
      fnd_file.put_line(fnd_file.log,'RUL:Header '||p_Header_Id);
	   v_URL_WB := APPS.wm_ol6_pkg.get_Page(reg_url.url||p_Header_Id, reg_url.username, reg_url.passwd, NULL);
	END LOOP;
	--
	--VALIDAR EL ESTADO DE EJECUCION DEL URL.
	--
	IF v_URL_WB = 0 THEN
		--
		--ESPERAR A QUE WEBMETHOS ACTUALICE LOS ESTATUS EN LA TABLA INTERFASE XXFC_SOLINV_CARGOCEN
		--
      --v_Segundos := TO_NUMBER(TO_CHAR(SYSDATE, 'SS')); --CHG0041613_9
      v_Hora_Inicio := sysdate; --CHG0041613_9
      fnd_file.put_line(fnd_file.log,'Hora inicio: '||v_Hora_Inicio);
		LOOP
		   FOR reg_SolInv_WM IN cur_SolInv_WM LOOP
			   --SI PASARON 30 SEGUNDO Y NO HUBO RESPUESTA SE SALE  Y ASIGNA ESTADO TIME-OUT
			   --IF (v_Segundos + 30) = TO_NUMBER(TO_CHAR(SYSDATE, 'SS')) THEN CHG0041613_9
            IF ((sysdate - v_Hora_Inicio) * 24 * 60 * 60) > 30 THEN --CHG0041613_9
               fnd_file.put_line(fnd_file.log,'Termina por tiempo: '||sysdate);
				   v_Estado := 'TO';
				   EXIT;
				END IF;
			   IF  reg_SolInv_WM.wm_status_val NOT IN ('L', 'F', 'A') OR
				    NVL(reg_SolInv_WM.wm_status_exec, 'X') NOT IN ('X', 'S', 'F') THEN
					 p_Mensaje := 'El STATUS Recuperado es Incompatible para la Solicitud de Inversion'
					              ||reg_SolInv_WM.si_number
									  ||CHR(10)||CHR(10)||'Pongase en Contacto con el Administrador del Sistema';
		          RETURN FALSE;
				ELSIF reg_SolInv_WM.wm_status_val = 'L' THEN
				   v_Count_WM := 0;
				   EXIT;
				ELSIF reg_SolInv_WM.wm_status_val = 'F' THEN
				   v_Estado := 'VF';
               v_Sol_Inversion := v_Sol_Inversion||reg_SolInv_WM.si_number||'/';
				ELSIF reg_SolInv_WM.wm_status_val = 'A' AND reg_SolInv_WM.wm_status_exec = 'F'
				AND reg_SolInv_WM.status_actualizacion IS NOT NULL THEN
				   v_Estado := 'EF';
					v_Sol_Inversion :=  v_Sol_Inversion||reg_SolInv_WM.si_number||'/';
				ELSIF reg_SolInv_WM.wm_status_val = 'A' AND reg_SolInv_WM.wm_status_exec = 'S'
				AND cur_SolInv_WM%ROWCOUNT = v_Count_CC AND v_Sol_Inversion IS NULL THEN
				   v_Estado := 'AS';
				ELSE
				   p_Mensaje := reg_SolInv_WM.status_actualizacion;
				END IF;
				v_Count_WM := cur_SolInv_WM%ROWCOUNT;
			END LOOP;
			--
			--CUANDO TERMINE DE VERIFICAR EL ESTADO DE TODOS LOS REGISTROS INGRESADOS PARA LA FACTURA SE SALE DEL LOOP
			--
			IF v_Estado = 'TO' THEN
			   -- SI EL ESTADO ES TIME-OUT SE SALE DE TODO
			   EXIT;
			END IF;
			IF v_Count_WM = v_Count_CC THEN
			   EXIT;
			END IF;
		END LOOP;
	ELSIF v_URL_WB = 1 THEN
	   p_Mensaje := 'ERROR Al Tratar de Ejecutar el URL.'
		             ||CHR(10)||CHR(10)||'Pongase en Contacto con el Administrador del Sistema';
	   RETURN FALSE;
	ELSIF v_URL_WB = 2 THEN
	   p_Mensaje := 'Configuracion Incorrecta para Ejecutar URL. NO hay Datos en WM_OL6_CONFIG'
		             ||CHR(10)||CHR(10)||'Pongase en Contacto con el Administrador del Sistema';
	   RETURN FALSE;
	END IF;

	--
	--DE ACUERDO AL ESTATUS MANDA EL MENSAJE DEL RESULTADO.
	--
	IF v_Estado = 'VF' THEN
	   p_Mensaje := 'NO hay Saldo Disponible para las Siguientes Solicitudes de Inversion'||v_Sol_Inversion;
	  RETURN FALSE;
	ELSIF v_Estado = 'EF' THEN
	   p_Mensaje := 'NO Se Ha Podido Afectar el Monto de las Siguientes Solicitudes de Inversion'||v_Sol_Inversion;
	   RETURN FALSE;
	ELSIF v_Estado = 'AS' THEN
	   p_Mensaje := 'Todos las Solicitudes de Inversion se han Validado y Aplicado Correctamente!';
	   RETURN TRUE;
	ELSIF v_Estado = 'TO' THEN
	   p_Mensaje := 'Tiempo de Espera Agotado. Ninguna Solicitud de Inversion ha sido Validada o Aplicada. Intentelo Mas Tarde';
	   RETURN FALSE;
	ELSE
	   RETURN FALSE;
	END IF;
EXCEPTION
   WHEN OTHERS THEN
	   p_Mensaje := 'ERROR Inesperado: '||SQLERRM
		             ||CHR(10)||CHR(10)||'Pongase en Contacto con el Administrador del Sistema';
		RETURN FALSE;
END Xxfc_Valida_Solinv;
/
SHOW ERRORS;