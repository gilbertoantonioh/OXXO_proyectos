DECLARE
   
   v_program_short_name    VARCHAR2(150) := '&1';                    -- Short_name del Concurrente
   v_program_application   VARCHAR2(10)  := '&2';                    -- Aplicacion del Concurrente
   v_request_group         VARCHAR2(150) := '&3';                    -- Nombre del Request Group
   v_group_application     VARCHAR2(50)  := '&4';                    -- Aplicacion del Request Group

   PROCEDURE ADD_TO_GROUP
   (
   p_program_short_name   VARCHAR2,
   p_program_application  VARCHAR2,
   p_request_group        VARCHAR2,
   p_group_application    VARCHAR2
   ) IS

   BEGIN

      IF NOT FND_PROGRAM.PROGRAM_IN_GROUP(
                                         program_short_name  => p_program_short_name,
                                         program_application => p_program_application,
                                         request_group       => p_request_group,
                                         group_application   => p_group_application
                                         ) THEN 

         FND_PROGRAM.ADD_TO_GROUP(
                                 program_short_name  => p_program_short_name,
                                 program_application => p_program_application,
                                 request_group       => p_request_group,
                                 group_application   => p_group_application    
                                 );

         COMMIT;

         dbms_output.put_line('Agregado a Request Group ' || p_request_group);
      ELSE

         dbms_output.put_line('El programa ' || v_program_short_name || ' ya se encuentra dado de alta en Request Group ' || p_request_group);

      END IF;

   END ADD_TO_GROUP;


BEGIN

   dbms_output.put_line('Se dara de alta el programa ' || v_program_short_name || ' en Request Groups.');

   IF FND_PROGRAM.PROGRAM_EXISTS(
                                program     => v_program_short_name,
                                application => v_program_application
                                ) THEN 

      ADD_TO_GROUP
      (
      p_program_short_name  => v_program_short_name,
      p_program_application => v_program_application,
      -- Info del Grupo de Solicitudes
      p_request_group       => v_request_group,
      p_group_application   => v_group_application
      );

   ELSE
      dbms_output.put_line('El programa ' || v_program_short_name || ' no existe dado de alta en la aplicacion.');
      dbms_output.put_line('Favor de instalarlo antes de agregar a Request Groups.');
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line('ERROR Inesperado...');
      dbms_output.put_line(SQLCODE || ' - ' || SQLERRM);
END;
/

