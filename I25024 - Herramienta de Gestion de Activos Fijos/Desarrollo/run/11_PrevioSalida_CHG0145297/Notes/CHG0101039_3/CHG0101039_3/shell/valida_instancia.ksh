instance=$1
ChOrder=$2
Correo=$3

instance2=""
install="N"


list=`$ORACLE_HOME/bin/sqlplus -s /nolog << EOF
connect $CONNECT_STRING
set heading off
set pagesize 0
set tab off
SELECT SALIDA1
FROM   XXFC_MAPEOS_VARIOS
WHERE  TIPO_MAPEO = 'ORACLE'
AND   ENTRADA = 'INSTANCIA'
/
exit
EOF`

for item in $list
do
   instance2=$item
   case $item in
      [$instance]*)
         install="Y";;
      *) install="N";;
   esac
done

case $install in
      [Y]*)
            echo "Se inicia con instalacion en la instancia correcta!!! "$instance;;
      *) 
            echo "ERROR!! Instalacion en instancia INCORRECTA " > validaIns.log
            echo "Se bede de instalar en "$instance" y se esta instalando en "$instance2 >> validaIns.log
            mailx -s "ERROR!! Instalacion en instancia INCORRECTA Change Order $ChOrder" $Correo < validaIns.log;;
esac
