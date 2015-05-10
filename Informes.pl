#!/usr/bin/perl -w

#!/usr/bin/perl -w
use Getopt::Long;

use constant false => 0;
use constant true  => 1;

main();


sub ayuda{
	imprimir("InfPro: El propósito de este comando es resolver consultas sobre los documentos protocolizados y emitir informes y estadisticas sobre ellos.");
	imprimir("Opciones:");
	imprimir("\ta:\t\tMostar ayuda.");
	imprimir("\tc:\t\tConsultar.");
	imprimir("\ti:\t\tInforme.");
	imprimir("\te:\t\tEstadisticas.");
	imprimir("\tgc:\t\tConsultar y guardar.");
	imprimir("\tgi:\t\tInforme y guardar.");
	imprimir("\tge:\t\tEstadisticas y guardar.");
	imprimir("\ts:\t\tSalir.");
}
sub imprimir {
    $a = shift."\n";
    print $a;
}

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

sub esAmbienteValido{
   my $PROCDIR = $ENV{'PROCDIR'};
   my $MAEDIR = $ENV{'MAEDIR'};
   my $INFODIR = $ENV{'INFODIR'};
   my $GRUPO = $ENV{'GRUPO'};

   if ( ! defined $GRUPO || $GRUPO eq "" || ! defined $PROCDIR || $PROCDIR eq "" || ! defined $MAEDIR || $MAEDIR eq "" || ! defined $INFODIR || $INFODIR eq "" )
   {
      imprimir("Ambiente no inicializado. Ejecute el comando . IniPro.sh");
      return false;
   }
   return true;

}

# Valida que no esté corriendo alguna instancia de InfPro

sub estaInfProCorriendo{

   my $InfProPIDCant=`ps ax | grep -v "grep" | grep -v "gedit" | grep -o "InfPro" | sed 's-\(^ *\)\([0-9]*\)\(.*\$\)-\2-g' | wc -l`;
   if ($InfProPIDCant > 1)
   {
      imprimir("Ya se está ejecutando el programa InfPro. Por favor, espere a que el mismo termine.");
      return false;
   }
   return true;

}

sub mostrarMenuPrencipal{
	imprimir ("MENU PRINCIPAL");
}

##ACA HAY QUE SETEAR DONDE SIGUE CORRIENDO DESPUES DE ELEGIR UNA OPCION
sub levantarProcesoOpcion{

	#primer parametro debe ser opciones
	$opcion = shift;
	if($opcion eq "a"){
		imprimir("parametro a");
		ayuda();
	}

	if($opcion eq "c"){
		imprimir("parametro c");
		consulta(false);
	}
	if($opcion eq "gc"){
		imprimir("parametro gc");
		consulta(true);
	}
	if($opcion eq "e"){
		imprimir("parametro e");
	}
	if($opcion eq "ge"){
		imprimir("parametro ge");
	}
	if($opcion eq "gi"){
		imprimir("parametro gi");
		informe(true);
	}
	if($opcion eq "i"){
		imprimir("parametro i");
		informe(false);
	}
	if($opcion eq "s"){
		imprimir("cerrando InfPro");
		exit 1;
	}
}

sub main{
   	if ( !esAmbienteValido()){
   		exit 1;
   	}

	if ( !estaInfProCorriendo() ){
		exit 1;
	}
			
	#mostrarMenuPrencipal();
	while(true){
		menuPrincipal();
	}
}

sub in_array {
  my ($item, $array) = @_;
  my %hash = map { $_ => 1 } @$array;
  if ($hash{$item}) { return 1; } else { return 0; }
}

sub menuPrincipal{
	ayuda();
	imprimir("Ingrese una opción: ");
	$entrada = <STDIN>;
	chomp($entrada);	
	
	#Loop infinito hasta que se ingrese opcion valida
	my @entradas=("a","c","gc","i","gi","e","ge","s", "");
	while(!in_array($entrada,\@entradas) ){
		imprimir("Opcion incorrecta. Intente nuevamente: ");
		$entrada = <STDIN>;
		chomp($entrada);
	}
	levantarProcesoOpcion($entrada);
	return $entrada;
}

sub consulta{
	$conGuardar= shift;
	imprimir("CONSULTANDOOOOOOOOOO");
	if($conGuardar){
		imprimir("guardando");
	}else{
		imprimir("sin Guardar");
	}
}

sub informe{
	$conGuardar= shift;
	imprimir("PREPARANDO INFORME");
	if($conGuardar){
		imprimir("guardando");
	}else{
		imprimir("sin Guardar");
	}

}

sub calcularPesoRegistro{
	my ($registro, $palabraClave) = @_;
	my ($causante, $extracto) = (split /;/, $registro)[8, 9];
	if ( $palabraClave ne ""){
		$peso=0;
		if($causante =~ /\Q$palabraClave\E/){
			$peso+=10;
		}
		if($extracto =~ /\Q$palabraClave\E/){
			$peso+=1;
		}
		return $peso;
	}
	return 0;
}
