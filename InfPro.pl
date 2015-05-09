#!/usr/bin/perl -w
use Getopt::Long;

use constant false => 0;
use constant true  => 1;

=pod
	$PROCDIR = $ENV{'PROCDIR'};
	$MAEDIR = $ENV{'MAEDIR'};
	$INFODIR = $ENV{'INFODIR'};
	$GRUPO = $ENV{'GRUPO'};

	print "$GRUPO$PROCDIR\n";
	print "$GRUPO$MAEDIR\n";
	print "$GRUPO$INFODIR\n";

	asignacion de variables
	my $PROCDIRCOMPLETO = $GRUPO.$PROCDIR;
	print "$PROCDIRCOMPLETO\n";

	my $MAEDIRCOMPLETO = $GRUPO.$MAEDIR;
	print "$MAEDIRCOMPLETO\n";

	my $INFODIRCOMPLETO = $GRUPO.$INFODIR;
	print "$INFODIRCOMPLETO\n";
=cut

##################################################

#indice para verificar el valor del argumento
my $j=0; 
my $directorio;
my $archivo;
##################################################

#Procesamiento de parametros de linea de comando
main();



##################################################
    

sub ayuda{
    imprimir("TEXTO DE AYUDA");
}
sub imprimir {
    $a = shift."\n";
    print $a;
};

sub cantidadDeParametros{
	$cantidad = $#ARGV;
	return $cantidad;
}

sub parametrosValidos{
	#acepta 1 o 2 parametros
	if ($#ARGV < 0  or $#ARGV > 1) {
		imprimir("todo mal");
		return false;
	}

	imprimir("todo bien");
	return true;
	
}

# Valida que el ambiente se haya inicializado con el IniPro.sh

sub validarAmbienteInicializado{
   my $PROCDIR = $ENV{'PROCDIR'};
   my $MAEDIR = $ENV{'MAEDIR'};
   my $INFODIR = $ENV{'INFODIR'};
   my $GRUPO = $ENV{'GRUPO'};

   if ( ! defined $GRUPO || $GRUPO eq "" || ! defined $PROCDIR || $PROCDIR eq "" || ! defined $MAEDIR || $MAEDIR eq "" || ! defined $INFODIR || $INFODIR eq "" )
   {
      print "Ambiente no inicializado. Ejecute el comando . IniPro.sh\n";
      return 1;
   }
   return 0;

}

# Valida que no esté corriendo alguna instancia de InfPro

sub validarInfProNoEsteCorriendo{

   my $InfProPIDCant=`ps ax | grep -v "grep" | grep -v "gedit" | grep -o "InfPro" | sed 's-\(^ *\)\([0-9]*\)\(.*\$\)-\2-g' | wc -l`;
   if ($InfProPIDCant > 1)
   {
      print "Ya se está ejecutando el programa InfPro. Por favor, espere a que el mismo termine.\n";
      return 1;
   }
   return 0;

}


sub logger{
	system("Glog.sh perl log INFO");
}

sub main{
	logger();
   	if ( validarAmbienteInicializado() == 0)
   	{
      		if ( validarInfProNoEsteCorriendo() == 0 )
       		{
			if (!parametrosValidos()) {
				imprimir("algo salio mal");
				ayuda();
				exit;
			}

			$parametroValido = false;
			#primer parametro debe ser opciones
			$opcion = $ARGV[0];
			if($opcion eq "-a"){
				imprimir("parametro -a");
				ayuda();
				$parametroValido = true;
			}
			if($opcion eq "-c"){
				imprimir("parametro -c");
				$parametroValido = true;
			}
			if($opcion eq "-i"){
				imprimir("parametro -i");
				$parametroValido = true;
			}
			if($opcion eq "-e"){
				imprimir("parametro -e");
				$parametroValido = true;
			}
			if($opcion eq "-cg"){
				imprimir("parametro -cg");
				$parametroValido = true;
			}
			if($opcion eq "-ig"){
				imprimir("parametro -ig");
				$parametroValido = true;
			}
			if($opcion eq "-eg"){
				imprimir("parametro -eg");
				$parametroValido = true;
			}
	
		}
	}
	
}
