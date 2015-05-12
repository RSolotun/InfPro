#! /usr/bin/perl -w

use Getopt::Long;
use List::MoreUtils qw(uniq);

use constant false => 0;
use constant true  => 1;

my $PROCDIR = $ENV{'PROCDIR'};
my $MAEDIR = $ENV{'MAEDIR'};
my $INFODIR = $ENV{'INFODIR'};
my $GRUPO = $ENV{'GRUPO'};
## Levanto a memoria los archivos de gestiones y emisores
my %hash_gestiones = cargarHashGestiones();
my %hash_emisores = cargarHashEmisores();
my %hash_normas = cargarHashNormas();
my %hash_gestionesOrdenadas = cargarHashGestionesOrdenadas();
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
    my $a = shift."\n";
    print $a;
}

sub cantidadDeParametros{
	my $cantidad = $#ARGV;
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
	my $opcion = shift;
	if($opcion eq "a"){
		imprimir("parametro a");
		ayuda();
	}
	if($opcion eq "c"){
		consulta(false);
	}
	if($opcion eq "gc"){
		consulta(true);
	}
	if($opcion eq "e"){
		estadistica(false);
	}
	if($opcion eq "ge"){
		estadistica(true);
	}
	if($opcion eq "gi"){
		informe(true);
	}
	if($opcion eq "i"){
		informe(false);
	}
	if($opcion eq "s"){
		imprimir("cerrando InfPro");
		exit 1;
	}
}

sub main{
   	if ( !esAmbienteValido() ){
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
	my $entrada = <STDIN>;
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
	my $conGuardar= shift;
	my $palabra_clave = ingresarPalabraClave();
	my @registros = filtrarRegistrosProtocolizados();
	my @registrosAOrdenar;
	foreach $reg (@registros){
		my ($causante,$extracto) = (split ";", $reg)[4,5];
		my $peso=calcularPesoRegistro($causante,$extracto,$palabra_clave);
		my $nuevoReg = $peso.";".$reg;
		push(@registrosAOrdenar,$nuevoReg);
	}
	my @regOrdPorFecha = sort{((split "/", (split ";", $b)[2])[2]).((split "/", (split ";", $b)[2])[1]).((split "/", (split ";", $b)[2])[0]) cmp ((split "/", (split ";", $a)[2])[2]).((split "/", (split ";", $a)[2])[1]).((split "/", (split ";", $a)[2])[0])} @registrosAOrdenar;
	my @regisrosOrdenados = sort{(split ";", $b)[0] <=> (split ";", $a)[0]} @regOrdPorFecha;
	foreach $reg (@regisrosOrdenados){
		my ($peso,$fechaNorma,$nroNorma,$anioNorma,$causante,$extracto,$codGestion,$codNorma,$codEmisor) = (split ";", $reg)[0,2,3,4,5,6,12,13,14];
		imprimir($codNorma." ".$hash_emisores{$codEmisor}."(".$codEmisor.") ".$nroNorma."/".$anioNorma." ".$codGestion." ".$fechaNorma." ".$peso);
		imprimir($causante);
		imprimir($extracto);
	}
	if($conGuardar){
		my $nombreArchivo = nombreArchivoConsultas();
		open(my $fh, '>', $nombreArchivo) || die "No puede abrirse el archivo $nombreArchivo\n";
		foreach $reg (@regisrosOrdenados){
			my ($fechaNorma,$nroNorma,$anioNorma,$causante,$extracto,$idReg,$codGestion,$codNorma,$codEmisor) = (split ";", $reg)[2,3,4,5,6,11,12,13,14];
			print $fh $codNorma.";".$hash_emisores{$codEmisor}.";".$codEmisor.";".$nroNorma.";".$anioNorma.";".$codGestion.";".$fechaNorma.";".$causante.";".$extracto.";".$idReg."\n";
		}
		close $fh;
		imprimir("Consulta grabada en $nombreArchivo");
	}
}

sub informe{
	my $conGuardar= shift;
	my @filtroArchivos = ingresarFiltroArchivos();
	my $palabra_clave = ingresarPalabraClave();
	my @registros = filtrarRegistrosConsultados(@filtroArchivos);
	my @registrosUnicos = uniq(@registros);
	my @registrosAOrdenar;
	foreach $reg (@registros){
		my ($causante,$extracto) = (split ";", $reg)[7,8];
		my $peso=calcularPesoRegistro($causante,$extracto,$palabra_clave);
		my $nuevoReg = $peso.";".$reg;
		push(@registrosAOrdenar,$nuevoReg);
	}
	my @regOrdPorFecha = sort{((split "/", (split ";", $b)[7])[2]).((split "/", (split ";", $b)[7])[1]).((split "/", (split ";", $b)[7])[0]) cmp ((split "/", (split ";", $a)[7])[2]).((split "/", (split ";", $a)[7])[1]).((split "/", (split ";", $a)[7])[0])} @registrosAOrdenar;
	my @regisrosOrdenados = sort{(split ";", $b)[0] <=> (split ";", $a)[0]} @regOrdPorFecha;
	foreach $reg (@regisrosOrdenados){
		my ($peso,$codNorma,$emisor,$codEmisor,$nroNorma,$anioNorma,$codGestion,$fechaNorma,$causante,$extracto,$idReg) = (split ";", $reg);
		imprimir($codNorma." ".$hash_emisores{$codEmisor}."(".$codEmisor.") ".$nroNorma."/".$anioNorma." ".$codGestion." ".$fechaNorma." ".$peso);
		imprimir($causante);
		imprimir($extracto);
	}
	if($conGuardar){
		my $nombreArchivo = nombreArchivoInformes();
		open(my $fh, '>', $nombreArchivo) || die "No puede abrirse el archivo $nombreArchivo\n";
		foreach $reg (@regisrosOrdenados){
			my ($peso,$codNorma,$emisor,$codEmisor,$nroNorma,$anioNorma,$codGestion,$fechaNorma,$causante,$extracto,$idReg) = (split ";", $reg);
			print $fh $codNorma.";".$hash_emisores{$codEmisor}.";".$codEmisor.";".$nroNorma.";".$anioNorma.";".$codGestion.";".$fechaNorma.";".$causante.";".$extracto.";".$idReg."\n";
		}
		close $fh;
		imprimir("Informe grabado en $nombreArchivo");
	}

}

sub estadistica{
	my $conGuardar= shift;
	my @registros = filtrarRegistrosProtocolizadosParaEstadisticas();
	my @regisrosOrdenados = sort{((split "/", (split ";", $a)[1])[2]).((split "/", (split ";", $a)[1])[1]).((split "/", (split ";", $a)[1])[0]) cmp ((split "/", (split ";", $b)[1])[2]).((split "/", (split ";", $b)[1])[1]).((split "/", (split ";", $b)[1])[0])} @registros;
	my @emisores;
	my $cantResoluciones = 0;
	my $cantDisposiciones = 0;
	my $cantConvenios = 0;
	my $gestionActual;
	my $anioActual;
	my %sumarizacionResoluciones;
	my %sumarizacionDisposiciones;
	my %sumarizacionConvenios;
	my %sumarizacionEmisores;
	foreach $reg (@regisrosOrdenados){
		my ($fechaNorma,$anioNorma,$codGestion,$codNorma,$codEmisor) = (split ";", $reg)[2,3,11,12,13];
		if ( not exists $sumarizacionEmisores{ $codGestion.";".$anioNorma } ){ 
			$cantResoluciones = 0;
			$cantDisposiciones = 0;
			$cantConvenios = 0;
			@emisores = ();
		}
		if ( $hash_norma{$codNorma} eq "RESOLUCION" ){$cantResoluciones++;}
		if ( $hash_norma{$codNorma} eq "DISPOSICION" ){$cantDisposiciones++;}
		if ( $hash_norma{$codNorma} eq "CONVENIO" ){$cantConvenios++;}
		my @aux = @emisores;
		push(@aux, $hash_emisores{$codEmisor});
		@emisores = uniq(@aux);
		$sumarizacionResoluciones{ $codGestion.";".$anioNorma } = $cantResoluciones;
		$sumarizacionDisposiciones{ $codGestion.";".$anioNorma } = $cantDisposiciones;
		$sumarizacionConvenios{ $codGestion.";".$anioNorma } = $cantConvenios;
		$sumarizacionEmisores{ $codGestion.";".$anioNorma } = [@emisores];
	}

	my @hash_claves_ordenadas = ordenarClavesEstadistica(keys %sumarizacionEmisores);
	foreach my $key (@hash_claves_ordenadas) {
		print ("Gestion: ".$hash_gestiones{(split ";", $key)[0]}." Año: ".(split ";", $key)[1]." Emisores: ");
		my $listaEmisores = "";
		foreach my $emisor (@{$sumarizacionEmisores{$key}}){
			$listaEmisores=$listaEmisores.", ".$emisor;
		}
		$listaEmisores=substr($listaEmisores,2);
		print $listaEmisores=$listaEmisores."\n";
		imprimir("Cantidad de resoluciones: ".$sumarizacionResoluciones{$key});
		imprimir("Cantidad de disposiciones: ".$sumarizacionDisposiciones{$key});
		imprimir("Cantidad de convenios: ".$sumarizacionConvenios{$key});
	}
	if($conGuardar){
		my $nombreArchivo = nombreArchivoEstadisticas();
		open(my $fh, '>', $nombreArchivo) || die "No puede abrirse el archivo $nombreArchivo\n";
		foreach my $key (@hash_claves_ordenadas) {
			print $fh ("Gestion: ".$hash_gestiones{(split ";", $key)[0]}." Año: ".(split ";", $key)[1]." Emisores: ");
			my $listaEmisores = "";
			foreach my $emisor (@{$sumarizacionEmisores{$key}}){
				$listaEmisores=$listaEmisores.", ".$emisor;
			}
			$listaEmisores=substr($listaEmisores,2);
			print $fh $listaEmisores=$listaEmisores."\n";
			print $fh "Cantidad de resoluciones: ".$sumarizacionResoluciones{$key}."\n";
			print $fh "Cantidad de disposiciones: ".$sumarizacionDisposiciones{$key}."\n";
			print $fh "Cantidad de convenios: ".$sumarizacionConvenios{$key}."\n";
		}
		close $fh;
		imprimir("Consulta grabada en $nombreArchivo");
	}
}

sub ordenarClavesEstadistica(){
	my @claves=@_;
	my @claves_ordenadas_por_anio = sort{ (split ";", $a)[1] <=> (split ";", $b)[1] } @claves;
	my @claves_ordenadas = sort{ $hash_gestionesOrdenadas{(split ";", $a)[0]} <=> $hash_gestionesOrdenadas{(split ";", $b)[0]} } @claves_ordenadas_por_anio;
	return (@claves_ordenadas);
}

sub calcularPesoRegistro{
	my ($causante, $extracto, $palabraClave) = @_;
	if ( $palabraClave ne ""){
		$auxPalabraClave=lc($palabraClave);
		$peso=0;
		$aux= () = lc($causante) =~ /$auxPalabraClave/g;
		$peso+=$aux*10;
		$peso+= () = lc($extracto) =~ /$auxPalabraClave/g;
		return $peso;
	}
	return 0;
}

sub pedirFiltros{
	my ($filtro_tipo_norma, $filtro_anios, $filtro_nro_norma, $filtro_gestion, $filtro_emisor) = @_;	
	$filtro_tipo_norma = ingresarFiltroPorTipoNorma();
	$filtro_anios = ingresarFiltroPorAnio(); 	     
	$filtro_nro_norma = ingresarFiltroPorNroNorma();
	$filtro_gestion = ingresarFiltroPorGestion();
	$filtro_emisor = ingresarFiltroPorEmisor();


	if ( ($filtro_tipo_norma eq "") && ($filtro_anios eq "") && ($filtro_nro_norma eq "") 
	             && ($filtro_gestion eq "") && ($filtro_emisor eq "") ){
		imprimir("Debe ingresar al menos un filtro !!!");
		pedirFiltros($filtro_tipo_norma, $filtro_anios, $filtro_nro_norma, $filtro_gestion, $filtro_emisor);
	}
	$_[0] = $filtro_tipo_norma;
	$_[1] = $filtro_anios;
	$_[2] = $filtro_nro_norma;
	$_[3] = $filtro_gestion;
	$_[4] = $filtro_emisor;
}

sub pedirFiltrosParaEstadisticas{
	my ($filtro_anios, $filtro_gestion) = @_;	
	$filtro_anios = ingresarFiltroPorAnio(); 	 
	$filtro_gestion = ingresarFiltroPorGestion();


	if ( ($filtro_anios eq "") && ($filtro_gestion eq "") ){
		imprimir("Se tomarán todas las posibles combinaciones de años y gestiones.");
	}
	$_[0] = $filtro_anios;
	$_[1] = $filtro_gestion;
}

sub ingresarPalabraClave{
	print "Ingrese palabra clave: ";
	my $palabra_clave = <STDIN>;
	chomp($palabra_clave);
	return $palabra_clave;
}

sub ingresarFiltroArchivos{
	print "Ingrese la lista de archivos resultado separados por coma: ";
	my $archivos = <STDIN>;
	chomp($archivos);
	@listaArchivos = (split",", $archivos);
	return @listaArchivos;
}

sub ingresarFiltroPorTipoNorma{
	print "Ingrese tipo de norma para filtrar: ";
	my $tipo_norma = <STDIN>;
	chomp($tipo_norma);
	my $tipo_norma_aux = $tipo_norma;
	$tipo_norma_aux =~ s/\s//g;	
	my $esValido = 0;
	
	# Validaciones
	while ( $esValido == 0 ){	
		if( ( length($tipo_norma) == 3 ) && ( $tipo_norma !~ /\d+/ ) && ( $tipo_norma eq $tipo_norma_aux ) ){
			$esValido = 1;
			return $tipo_norma;
		}
		elsif ($tipo_norma eq ""){
			return $tipo_norma;
		}
		else{
			print "Norma invalida. Ingrese nuevamente: ";
			$tipo_norma = <STDIN>;
			chomp($tipo_norma);
			$tipo_norma_aux = $tipo_norma;
			$tipo_norma_aux =~ s/\s//g;
		}
			
	}				 	
}

sub ingresarFiltroPorAnio{

	print "Ingrese rango de años para filtrar con el formato ####-####: ";
	my $rango_anios = <STDIN>;
	chomp($rango_anios);
	
	$rango_anios = validarRangoAnios($rango_anios);		

	return $rango_anios;				
}

sub validarRangoAnios{
	my $rango_anios = $_[0];
	my $esValido = 0;
	
	while ( $esValido == 0 ){
		if( ( ( length($rango_anios) == 9 ) && ( $rango_anios =~ /[0-9]{4}.[0-9]{4}/ ) ) || ( length($rango_anios) == 0 )){
			return $rango_anios;
		}
		else{
			print "Rango invalido. Ingrese nuevamente: ";
			$rango_anios = <STDIN>;
			chomp($rango_anios);
		}
	}
}

sub ingresarFiltroPorNroNorma{
	
	print "Ingrese rango de números de norma para filtrar con el formato ####-####: ";
	my $rango_nro_norma = <STDIN>;
	chomp($rango_nro_norma);
	my $esValido = 0;

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

sub ingresarFiltroPorGestion{
	print "Ingrese una gestion para filtrar: ";
	my $gestion = <STDIN>;
	chomp($gestion);
	my $esValido = 0;

	while ( $esValido == 0 ){
		if (($gestion =~ /[0-9]$/ ) && ($gestion =~ /^[^0-9]*.$/ )){
			return $gestion;
		}
		elsif (($gestion =~ /[A-Za-z]+/) && ( $gestion =~ /^[^0-9]*.$/ )){
			return $gestion;
		}
		elsif ($gestion eq ""){
			return $gestion;
		}
		else {
			print "Gestion invalida. Ingrese nuevamente: ";
			$gestion = <STDIN>;
			chomp($gestion);
		}
	}
}

sub ingresarFiltroPorEmisor{
	print "Ingrese un emisor para filtrar: ";
	my $emisor = <STDIN>;
	chomp($emisor);	
	my $esValido = 0;
	
	# Validaciones
	while ( $esValido == 0 ){	
		if (($emisor =~ /[0-9]$/ ) && ($emisor =~ /^[^0-9]*.$/ )){
			return $emisor;
		}
		elsif (($emisor =~ /[A-Za-z]+/) && ( $emisor =~ /^[^0-9]*.$/ )){
			return $emisor;
		}
		elsif ($emisor eq ""){
			return $emisor;
		}
		else {
			print "Emisor invalido. Ingrese nuevamente: ";
			$emisor = <STDIN>;
			chomp($emisor);
		}
	}		
}

sub cargarHashArchivosProtocolizados{
	my %hash_archivos;
	my @archivosProtocolizados = cargarArchivosProtocolizados($GRUPO.$PROCDIR);
	foreach my $archivo (@archivosProtocolizados){
		chomp($archivo);
		my $auxArchivo=$archivo;
		my $aux= () = $auxArchivo =~ /\//g;
		while ( $aux > 1 ){
  			substr($auxArchivo, 0, index($auxArchivo, '/')+1) = '';
			$aux= () = $auxArchivo =~ /\//g;
		}
		my ($gestion, $nombreArchivo)=(split "\/", $auxArchivo);
		my ($anioNorma, $codNorma)=(split /\./, $nombreArchivo);
		$hash_archivos{ $gestion.";".$anioNorma.";".$codNorma } = $archivo;
	}
	return %hash_archivos;
}

sub cargarArchivosProtocolizados{
	my $directorio_padre = $_[0];
	my @rutas;
	opendir(DP, $directorio_padre) || die "No puede abrirse el directorio $directorio_padre\n";

	while (my $nombre_directorio_hijo = readdir(DP)) {
		if ( ($nombre_directorio_hijo ne ".") && ($nombre_directorio_hijo ne "..")  && ($nombre_directorio_hijo ne "proc") ){
			$nombre_directorio_hijo = $directorio_padre."/".$nombre_directorio_hijo."/";
			if(-e $nombre_directorio_hijo){    
				opendir(DH, $nombre_directorio_hijo) || die "No puede abrirse el directorio $nombre_directorio_hijo";
				while (my $archivo = readdir(DH)) {
					if ( ($archivo ne ".") && ($archivo ne "..") ){
						$archivo = $nombre_directorio_hijo.$archivo;
						push(@rutas,$archivo);
					}
				}
				close(DH);
			}
		}
	}
	closedir(DP);
	return (@rutas);
}

sub cargarArchivosDeConsultas{
	my @filtroArchivos = @_;
	my $dir = $GRUPO.$INFODIR;
	my @archivos = cargarArchivos($dir);
	my @archivos_consultas;

	if ( scalar(@filtroArchivos) == 0){
		foreach my $archivo (@archivos){
			my $aux = $archivo;
			chomp($archivo);
			substr($archivo, 0, rindex($archivo, '/')+1) = '';
			if ( $archivo =~ /resultados/g ){
				push(@archivos_consultas, $aux);
			}
		}	
	}else{
		foreach my $archivo (@archivos){
			my $aux = $archivo;
			chomp($archivo);
			substr($archivo, 0, rindex($archivo, '/')+1) = '';
			foreach my $archivoFiltro (@filtroArchivos){
				if ( $archivo eq $archivoFiltro ){
					push(@archivos_consultas, $aux);
				}
			}
		}
	}
	
	return (@archivos_consultas);
}

sub cargarArchivos{
	my $directorio_padre = $_[0];
	my @rutas;
	opendir(DP, $directorio_padre) || die "No puede abrirse el directorio $directorio_padre\n";

	while (my $archivo = readdir(DP)) {
		if ( ($archivo ne ".") && ($archivo ne "..") ){
			push(@rutas,$directorio_padre."/".$archivo);
		}
	}
	closedir(DP);
	return (@rutas);
}

sub cargarHashGestiones{
	my %hash_gestiones;
	my $direccion_gestiones = $GRUPO.$MAEDIR."/gestiones.mae";
	open (FILE, $direccion_gestiones) || die "Error al abrir archivo de gestiones.mae";
	while(my $reg = <FILE>){
		my ($cod_gestion, $descripcion) = (split";", $reg)[0,3];
		$hash_gestiones{$cod_gestion} = $descripcion;
	}
	close(FILE);
	return (%hash_gestiones);
}

sub cargarHashGestionesOrdenadas{
	my %hash_gestiones;
	my $direccion_gestiones = $GRUPO.$MAEDIR."/gestiones.mae";
	open (FILE, $direccion_gestiones) || die "Error al abrir archivo de gestiones.mae";
	my $orden = 0;
	while(my $reg = <FILE>){
		my ($cod_gestion) = (split";", $reg)[0];
		$hash_gestiones{$cod_gestion} = $orden;
		$orden++;
	}
	close(FILE);
	return (%hash_gestiones);
}

sub cargarHashEmisores{
	my %hash_emisores;
	my $direccion_emisores = $GRUPO.$MAEDIR."/emisores.mae";
	open(FILE, $direccion_emisores) || die "Error al abrir archivo de emisores.mae";
	while(my $reg = <FILE>){
		my ($cod_emisor, $nombre_emisor) = (split";", $reg)[0,1];
		$hash_emisores{$cod_emisor} = $nombre_emisor;
	}
	close(FILE);
	return (%hash_emisores);
}

sub cargarHashNormas{
	my %hash_normas;
	my $direccion_normas = $GRUPO.$MAEDIR."/normas.mae";
	open(FILE, $direccion_normas) || die "Error al abrir archivo de normas.mae";
	while(my $reg = <FILE>){
		my ($cod_norma, $nombre_norma) = (split";", $reg)[0,1];
		$hash_norma{$cod_norma} = $nombre_norma;
	}
	close(FILE);
	return (%hash_normas);
}

sub filtrarRegistrosConsultados{
	my @archivos = cargarArchivosDeConsultas(@_);
	my @regsistrosValidos;
	pedirFiltros($filtro_tipo_norma, $filtro_anios, $filtro_nro_norma, $filtro_gestion, $filtro_emisor);
	foreach my $archivo ( @archivos ) {
		open (FILE, $archivo) or die "Falla al abrir $archivo";
		while ($reg = <FILE>){
			chomp($reg);
			my($codNorma, $codEmisor, $nroNorma, $anioNorma, $gestion) = (split ";", $reg)[0,2,3,4,5];
			if($filtro_gestion ne ""){
				my $descGestion = $hash_gestiones{$gestion};
				my $aux = lc($filtro_gestion);
				if( lc($descGestion) !~ /$aux/g){
					next;
				}
			}
			if($filtro_anios ne ""){
				my ($filtroDesde, $filtroHasta) = (split "-" , $filtro_anios);
				if($filtroDesde > $anioNorma || $filtroHasta < $anioNorma){
					next;
				}
			}
			if($filtro_tipo_norma ne ""){
				if(lc($filtro_tipo_norma) ne lc($codNorma)){
					next;
				}		
			}
			if($filtro_nro_norma ne ""){
				my ($filtroDesde, $filtroHasta) = (split "-" , $filtro_nro_norma);
				if($filtroDesde > $nroNorma || $filtroHasta < $nroNorma){
					next;
				}		
			}
			if($filtro_emisor ne ""){
				my $descEmisor = $hash_emisores{$codEmisor};
				my $aux = lc($filtro_emisor);
				if( lc($descEmisor) !~ /$aux/g ){
					next;
				}		
			}
			push(@regsistrosValidos, $reg);
		} 
		close(FILE);
	}
	return (@regsistrosValidos);
}

sub filtrarRegistrosProtocolizados{
	#hash_archivos; key=$gestion.";".$anioNorma.";".$codNorma; value=$archivo
	my %hash_archivos = cargarHashArchivosProtocolizados();
	my @regsistrosValidos;
	pedirFiltros($filtro_tipo_norma, $filtro_anios, $filtro_nro_norma, $filtro_gestion, $filtro_emisor);
	foreach my $key ( keys %hash_archivos ) {
		my ($gestion, $anioNorma, $codNorma) = (split ";" , $key);
		if($filtro_gestion ne ""){
			my $descGestion = $hash_gestiones{$gestion};
			my $aux = lc($filtro_gestion);
			if( lc($descGestion) !~ /$aux/g){
				next;
			}
		}
		if($filtro_anios ne ""){
			my ($filtroDesde, $filtroHasta) = (split "-" , $filtro_anios);
			if($filtroDesde > $anioNorma || $filtroHasta < $anioNorma){
				next;
			}
		}
		if($filtro_tipo_norma ne ""){
			if(lc($filtro_tipo_norma) ne lc($codNorma)){
				next;
			}		
		}
		open (FILE, $hash_archivos{$key}) or die "Falla al abrir $hash_archivos{$key}";
		while ($reg = <FILE>){
			chomp($reg);
			my($codEmisor, $nroNorma) = (split ";", $reg)[13,2];
			if($filtro_nro_norma ne ""){
				my ($filtroDesde, $filtroHasta) = (split "-" , $filtro_nro_norma);
				if($filtroDesde > $nroNorma || $filtroHasta < $nroNorma){
					next;
				}		
			}
			if($filtro_emisor ne ""){
				my $descEmisor = $hash_emisores{$codEmisor};
				my $aux = lc($filtro_emisor);
				if( lc($descEmisor) !~ /$aux/g ){
					next;
				}		
			}
			push(@regsistrosValidos, $reg);
		}
		close(FILE);
	}
	return (@regsistrosValidos);
}

sub filtrarRegistrosProtocolizadosParaEstadisticas{
	#hash_archivos; key=$gestion.";".$anioNorma.";".$codNorma; value=$archivo
	my %hash_archivos = cargarHashArchivosProtocolizados();
	my @regsistrosValidos;
	pedirFiltrosParaEstadisticas($filtro_anios, $filtro_gestion);
	foreach my $key ( keys %hash_archivos ) {
		my ($gestion, $anioNorma, $codNorma) = (split ";" , $key);
		if($filtro_gestion ne ""){
			my $descGestion = $hash_gestiones{$gestion};
			my $aux = lc($filtro_gestion);
			if( lc($descGestion) !~ /$aux/g){
				next;
			}
		}
		if($filtro_anios ne ""){
			my ($filtroDesde, $filtroHasta) = (split "-" , $filtro_anios);
			if($filtroDesde > $anioNorma || $filtroHasta < $anioNorma){
				next;
			}
		}
		open (FILE, $hash_archivos{$key}) or die "Falla al abrir $hash_archivos{$key}";
		while ($reg = <FILE>){
			chomp($reg);
			push(@regsistrosValidos, $reg);
		}
		close(FILE);
	}
	return (@regsistrosValidos);
}

sub nombreArchivoConsultas{
	my $dir = $GRUPO.$INFODIR;
	my @archivos = cargarArchivos($dir);
	
	my $ultimoNroUsado=0;

	foreach my $archivo (@archivos){
		chomp($archivo);
		substr($archivo, 0, rindex($archivo, '/')+1) = '';
		if ( $archivo =~ /resultados/g ){
			$nro=(split "_", $archivo)[1];
			if ($ultimoNroUsado < $nro){
				$ultimoNroUsado = $nro;
			}
		}
	}	
	my $sigNro = $ultimoNroUsado + 1;
	my $result = sprintf('%03d',$sigNro);
	my $nombreArchivo = $GRUPO.$INFODIR."/resultados_".$result;
	return $nombreArchivo;
}

sub nombreArchivoInformes{
	my $dir = $GRUPO.$INFODIR;
	my @archivos = cargarArchivos($dir);
	
	my $ultimoNroUsado=0;

	foreach my $archivo (@archivos){
		chomp($archivo);
		substr($archivo, 0, rindex($archivo, '/')+1) = '';
		if ( $archivo =~ /informe/g ){
			$nro=(split "_", $archivo)[1];
			if ($ultimoNroUsado < $nro){
				$ultimoNroUsado = $nro;
			}
		}
	}	
	my $sigNro = $ultimoNroUsado + 1;
	my $result = sprintf('%03d',$sigNro);
	my $nombreArchivo = $GRUPO.$INFODIR."/informe_".$result;
	return $nombreArchivo;
}

sub nombreArchivoEstadisticas{
	my $dir = $GRUPO.$INFODIR;
	my @archivos = cargarArchivos($dir);
	
	my $ultimoNroUsado=0;

	foreach my $archivo (@archivos){
		chomp($archivo);
		substr($archivo, 0, rindex($archivo, '/')+1) = '';
		if ( $archivo =~ /estadistica/g ){
			$nro=(split "_", $archivo)[1];
			if ($ultimoNroUsado < $nro){
				$ultimoNroUsado = $nro;
			}
		}
	}	
	my $sigNro = $ultimoNroUsado + 1;
	my $result = sprintf('%03d',$sigNro);
	my $nombreArchivo = $GRUPO.$INFODIR."/estadistica_".$result;
	return $nombreArchivo;
}
