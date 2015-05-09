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


sub logger{
	system("Glog.sh perl log INFO");
}

sub main{
	logger();
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
