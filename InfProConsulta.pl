#!/usr/bin/perl -w
use Getopt::Long;

use constant false => 0;
use constant true  => 1;

consulta(true);
#main();


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
		consulta(true);
	}
	if($opcion eq "gc"){
		imprimir("parametro gc");
		consulta(false);
	}
	if($opcion eq "e"){
		imprimir("parametro e");
	}
	if($opcion eq "ge"){
		imprimir("parametro ge");
	}
	if($opcion eq "gi"){
		imprimir("parametro gi");
	}
	if($opcion eq "i"){
		imprimir("parametro i");
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
	$palabraClave = pedirPalabraClave();
	$tipoDeNorme = pedirCodNorma();
	$rangoAnios = pedirFiltroPorAnio();
	$nroNorma = pedirFiltroPorNroNorma();
	$codGestion = pedirFiltroPorCodGestion();
	$codEmisor = pedirFiltroPorCodEmisor();

	#imprimir("zarasa: ".$todasLasGestiones{"Alfonsin"});
	%gestionesProcesadas = gestionesProcesadas();

	imprimir("palabraClave: ".$palabraClave );
	imprimir("tipoDeNorme: ".$tipoDeNorme);
	imprimir("rangoAnios: ".$rangoAnios);
	imprimir("nroNorma: ".$nroNorma);
	imprimir("codGestion: ".$codGestion);
	imprimir("codEmisor: ".$codEmisor);

}

sub recorrerHash{
	 while ( my ($key, $value) = each(%todasLasGestiones) ) {
        print "$key => $value\n";
    }
}

sub buscarTodasLasGestiones{
	imprimir("buscando");

	my $PROCDIR = $ENV{'PROCDIR'};
	my $MAEDIR = $ENV{'MAEDIR'};
	my $INFODIR = $ENV{'INFODIR'};
	my $GRUPO = $ENV{'GRUPO'};
	my %hash_gestiones = ();
	$gestionesFile=$GRUPO.$MAEDIR."/gestiones.mae";
	open(FILE, $gestionesFile) || die "Error al abrir archivo de gestiones.mae";
	while(my $reg = <FILE>){
		my @regs = split(";", $reg);
		my $cod_gestion = $regs[0];
		my $descripcion = $regs[3];
		#imprimir($cod_gestion. " - ".$descripcion);
		$hash_gestiones{$cod_gestion} = $descripcion;
	}
	close(FILE);
	return %hash_gestiones;
}

sub gestionesProcesadas{
	my $PROCDIR = $ENV{'PROCDIR'};
	my $GRUPO = $ENV{'GRUPO'};	
	%todasLasGestiones = buscarTodasLasGestiones();
	%gestionesProcesadas = ();
	$dir = $GRUPO.$PROCDIR;
	opendir(DIR, "$dir");

	@FILES = readdir(DIR);
	foreach $file (@FILES) {
		 while ( my ($key, $value) = each(%todasLasGestiones) ) {
	        if($key eq $file){
	        	#imprimir($key);
	        	$gestionesProcesadas{$key}=$value;
	        }
		}

	}
	closedir(DIR);
	return %gestionesProcesadas;
}

sub pedirPalabraClave{
	print "Ingrese palabra clave (mandato): ";
	$palabra_clave = <STDIN>;
	chomp($palabra_clave);
	return $palabra_clave;
}


sub pedirCodNorma{
	print "Ingrese filtro por codigo de norma (CON): ";
	$cod_norma = <STDIN>;
	chomp($cod_norma);
	$cod_norma_aux = $cod_norma;
	$cod_norma_aux =~ s/\s//g;	
	$esValido = 0;
	
	# Validaciones
	while ( $esValido == 0 ){	
		if( ( length($cod_norma) == 3 ) && ( $cod_norma !~ /\d+/ ) && ( $cod_norma eq $cod_norma_aux ) ){
			$esValido = 1;
			return $cod_norma;
		}
		elsif ($cod_norma eq ""){
			return $cod_norma;
		}
		else{
			print "Codigo de norma invalido. Ingrese nuevamente: ";
			$cod_norma = <STDIN>;
			chomp($cod_norma);
			$cod_norma_aux = $cod_norma;
			$cod_norma_aux =~ s/\s//g;
		}
			
	}				 	
}

sub pedirFiltroPorAnio{

	print "Ingrese un rango de anios (1974-1989): ";
	$rango_anios = <STDIN>;
	chomp($rango_anios);
	
	$rango_anios = validarRangoAnios($rango_anios);		

	return $rango_anios;				
}

sub validarRangoAnios{
	$rango_anios = $_[0];
	$esValido = 0;
	
	while ( $esValido == 0 ){
		if( ( ( length($rango_anios) == 9 ) && ( $rango_anios =~ /[0-9]{4}.[0-9]{4}/ ) ) || ( length($rango_anios) == 0 )){
			return $rango_anios;
		}else{
			print "Rango invalido. Ingrese nuevamente: ";
			$rango_anios = <STDIN>;
			chomp($rango_anios);
		}
	}
}

sub pedirFiltroPorNroNorma{
	
	print "Ingrese un rango Numero de Norma (0001-7345): ";
	$rango_nro_norma = <STDIN>;
	chomp($rango_nro_norma);
	$esValido = 0;

	while ( $esValido == 0 ){
		if ( ( ($rango_nro_norma =~ /[0-9]{4}.[0-9]{4}/) && ( length($rango_nro_norma) == 9 ) ) || (length($rango_nro_norma) == 0) ){				
			return $rango_nro_norma;		
		}
		else{
			print "Rango invalido. Ingrese nuevamente: ";
			$rango_nro_norma = <STDIN>;
			chomp($rango_nro_norma);
		}
	}		
}

sub pedirFiltroPorCodGestion{
	print "Ingrese un Codigo de Gestion (Illia): ";
	my $cod_gestion = <STDIN>;
	chomp($cod_gestion);
	my $esValido = 0;

	while ( $esValido == 0 ){
		if (($cod_gestion =~ /[0-9]$/ ) && ($cod_gestion =~ /^[^0-9]*.$/ )){
			return $cod_gestion;
		}
		elsif (($cod_gestion =~ /[A-Za-z]+/) && ( $cod_gestion =~ /^[^0-9]*.$/ )){
			return $cod_gestion;
		}
		elsif ($cod_gestion eq ""){
			return $cod_gestion;
		}
		else {
			print "Codigo de Gestion invalido. Ingrese nuevamente: ";
			$cod_gestion = <STDIN>;
			chomp($cod_gestion);
		}
	}
}

sub pedirFiltroPorCodEmisor{
	print "Ingrese un Codigo de Emisor (4444): ";
	$cod_emisor = <STDIN>;
	chomp($cod_emisor);
	
	$cod_emisor_aux = $cod_emisor;
	$cod_emisor_aux =~ s/\s//g;	
	$esValido = 0;
	
	# Validaciones
	while ( $esValido == 0 ){	
		if( ( ( $cod_emisor !~ /\D+/ ) && ( $cod_emisor eq $cod_emisor_aux ) ) || (length($cod_emisor) == 0) ){
			return $cod_emisor;
		}
		else{
			print "Codigo de emisor invalido. Ingrese nuevamente: ";
			$cod_emisor = <STDIN>;
			chomp($cod_emisor);
			$cod_emisor_aux = $cod_emisor;
			$cod_emisor_aux =~ s/\s//g;
		}
	}		
}
