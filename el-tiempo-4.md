# Parte 4 - El menú y la temperatura

En la parte anterior utilizamos algunas funcionalidades básicas de `Raku` que incorporamos en nuestra aplicación:
* Creamos un módulo de `Raku` para alojar y disponer de la función `get-url`
* Definimos la estructura de carpetas y archivos de una aplicación básica de `Raku`
* Implementamos una gramática para obtener ciudades y sus coordenadas a partir de código HTML descargado con `get-url`
* Utilizamos un hash denominado `%cities-lat-lon` para guardar y disponer de las ciudades y sus coordenadas

Utilizando el hash `%cities-lat-lon` podemos averiguar la latitud de una ciudad `$city` de la siguiente manera:
```raku
%cities-lat-lon{$city}<latitude>
```
y la longitud con:
```raku
%cities-lat-lon{$city}<longitude>
```
Con la latitud y la longitud de una ciudad construiremos la URL correspondiente, como vimos en la primera parte, para descargar la información climática correspondiente de dicha ciudad y obtener la temperatura.

Pensemos ahora en cómo vamos a interaccionar con el usuario para pedirle una ciudad, obtener su temperatura y mostrársela.

## Un menú para elegir una ciudad

Tenemos 65 ciudades para mostrar al usuario y pedirle una de ellas. En esta situación y para facilitar la búsqueda y elección, mostraremos las ciudades ordenadas alfabéticamente y a cada una le asignaremos un número consecutivo a su izquierda. Para que el menú no exceda los límites verticales de la pantalla, mostraremos las ciudades distribuidas en cuatro columnas, de la siguiente manera:
```
 1 Abu Dhabi         2 Algiers           3 Amsterdam         4 Ankara           
 5 Asuncion          6 Athens            7 Baghdad           8 Berlin           
 9 Bern             10 Bogota           11 Brasilia         12 Brussels         
13 Budapest         14 Buenos Aires     15 Cairo            16 Canberra         
17 Chicago          18 Ciudad de Mexico 19 Copenhagen       20 Dhaka            
21 Dublin           22 Houston          23 Jakarta          24 Jerusalem        
25 Kabul            26 Kathmandu        27 Kiev             28 Kuala Lumpur     
29 Lima             30 Lisabon          31 London           32 Los Angeles      
33 Luanda           34 Madrid           35 Montevideo       36 Moscow           
37 Nairobi          38 New Delhi        39 New York         40 Oslo             
41 Ottawa           42 Paris            43 Peking           44 Philadelphia     
45 Phoenix          46 Pretoria         47 Reykjavik        48 Rome             
49 Sacramento       50 Santiago         51 Seoul            52 Singapore        
53 Sofia            54 Stockholm        55 Teheran          56 Tiflis           
57 Tokyo            58 Tripoli          59 Ulan Bator       60 Vancouver        
61 Vienna           62 Warsaw           63 Washington       64 Wellington       
65 Windhoek         

Enter city number to show the current temperature. Another number = exit: 
```
En la parte inferior del menú aparece un mensaje donde pide el número de una ciudad o cualquier otro número para salir.

Introducido un número entre `1` y `65` y pulsando `ENTER`, la aplicación obtendrá la temperatura correspondiente de la ciudad introducida. Por ejemplo, si introducimos el número `34` correspondiente a la ciudad de Madrid y después pulsamos `ENTER`, veremos su temperatura actual de la siguiente forma:
```
 1 Abu Dhabi         2 Algiers           3 Amsterdam         4 Ankara           
 5 Asuncion          6 Athens            7 Baghdad           8 Berlin           
 9 Bern             10 Bogota           11 Brasilia         12 Brussels         
13 Budapest         14 Buenos Aires     15 Cairo            16 Canberra         
17 Chicago          18 Ciudad de Mexico 19 Copenhagen       20 Dhaka            
21 Dublin           22 Houston          23 Jakarta          24 Jerusalem        
25 Kabul            26 Kathmandu        27 Kiev             28 Kuala Lumpur     
29 Lima             30 Lisabon          31 London           32 Los Angeles      
33 Luanda           34 Madrid           35 Montevideo       36 Moscow           
37 Nairobi          38 New Delhi        39 New York         40 Oslo             
41 Ottawa           42 Paris            43 Peking           44 Philadelphia     
45 Phoenix          46 Pretoria         47 Reykjavik        48 Rome             
49 Sacramento       50 Santiago         51 Seoul            52 Singapore        
53 Sofia            54 Stockholm        55 Teheran          56 Tiflis           
57 Tokyo            58 Tripoli          59 Ulan Bator       60 Vancouver        
61 Vienna           62 Warsaw           63 Washington       64 Wellington       
65 Windhoek         

       City: 34 Madrid
Temperature: 11.3 °C

Enter city number to show the current temperature. Another number = exit: 
```
De esta manera mostramos la ciudad elegida y su temperatura. Además, pedimos de nuevo al usuario si quiere consultar la temperatura de otra ciudad, o si quiere salir de la aplicación.

## Construyendo el menú

Como cada elemento del menú se compone de un número y una ciudad, necesitaremos otro hash que denominaremos `%cities-lat-lon-sorted` donde guardaremos cada uno de estos elementos ordenados alfabéticamente por el nombre de ciudad. Esta ordenación alfabética de ciudades es fundamental para construir el menú como veremos después. Dentro de este hash, la clave de cada elemento será el número de la ciudad y el valor correspondiente incluirá el nombre de una ciudad, su latitud y su longitud. Así, proporcionando al nuevo hash un número (desde el menú, como hemos visto), obtendremos automáticamente cualquiera de estos tres valores. Construiremos este nuevo hash a partir del que ya tenemos `%cities-lat-lon`.  

Además, aprovecharemos la construcción del nuevo hash para construir también el menú en una variable de texto denominada `$menu` donde necesitaremos también otras variables de apoyo:
```raku
my $menu        = "\n";
my $menu-cols   = 4;
my $last-col    = $menu-cols;
my $city-number = 1;
```
Como vemos, `$menu` comienza con una línea en blanco `"\n"`. Con esto dejamos un oportuno espacio superior por encima del menú para facilitar su visualización.

El número de columnas `4` del menú irá en `$menu-cols;`. 

Para saltar de línea al llegar a la cuarta ciudad de una línea utilizaremos `$last-col` que comenzará con la columna `4` que a su vez viene de `$menu-cols`.

Por último tendremos en cuenta el número de cada ciudad ordenada con `$city-number` comenzando con `1`.

Vamos a contruir el nuevo hash `%cities-lat-lon-sorted` y el `$menu` a la vez a partir del hash `%cities-lat-lon` de la siguiente manera:
```raku
my %cities-lat-lon-sorted = gather for %cities-lat-lon.sort(*.key)>>.kv -> ($city, $data) {

    take $city-number => {
        'city'      => $city,
        'latitude'  => $data.<latitude>,
        'longitude' => $data.<longitude>
    }

    $menu ~= sprintf "%2s %-17s", $city-number, $city;

    if $city-number == $last-col {
        $menu ~= "\n";
        $last-col += $menu-cols;
    }

    $city-number++;
}
```
Como ya hemos visto antes de forma parecida, directamente definimos el nuevo hash a partir del existente con `gather`:
```raku
my %cities-lat-lon-sorted = gather for %cities-lat-lon.sort(*.key)>>.kv -> ($city, $data) {
```
Después de `gather` iteramos con `for` en cada ciudad del hash `$cities-lat-lon`, pero de forma ordenada por ciudad (que es la clave) utilizando el método `.sort(*.key)`, y devolviendo por cada ciudad su clave y valor `>>.kv -> ($city, $data)`. La clave la obtendremos en `$city` y el valor en `$data`. En `$data` viene incluida la latitud y la longitud de la ciudad.

De esta manera, en la primera vuelta `$city-number` es `1`, la ciudad `$city` es `Abu Dhabi` y su latitud y longitud vendrá en `$data` como indicamos. Ahora veremos como obtener esta información de la latitud y la longitud a partir de `$data`.

Con `take` construimos el primer elemento del nuevo hash ordenado `%cities-lat-lon-sorted`:
```raku
take $city-number => {
    'city'      => $city,
    'latitude'  => $data.<latitude>,
    'longitude' => $data.<longitude>
}
```
En la primera vuelta ya tenemos el primer elemento con clave `1` del nuevo hash. A continuación agregaremos el primer elemento del `$menu` que será:
```
1 Abu Dhabi
```
de la siguiente forma:

```raku
$menu ~= sprintf "%2s %-17s", $city-number, $city;
```
Los operadores `~=` agregan texto a `$menu`. Este texto, correspondiente al número y al nombre de la primera ciudad se compone de `$city-number` que es `1`, un espacio en blanco y el nombre de la ciudad `$city` que es `Abu Dhabi`. Para conseguir que cada número y nombre de ciudad ocupen el mismo ancho para que las columnas queden perfectamente alineadas utilizaremos la función `sprintf`. Esta función sirve para especificar formatos de texto y en nuestro caso utiliza tres parámetros separados por comas: 

1. `"%2s %-17s"` es el primer parámetro que viene a decir: un formato `%` con `2` posiciones para un texto `s`, un espacio y otro formato `%` justificado a la izquierda `-` con `17` posiciones para un texto `s`. El primer formato se corresponde con el número de la ciudad y el segundo formato se corresponde con el nombre de la ciudad como veremos a continuación

2. `$city-number` se corresponde con el formato `%2s`. En este primer caso será un espacio y el número `1` (dos posiciones) justificado a la derecha. Cuando este número llegue a tener dos posiciones `10`, pues ya ocupará dos posiciones.

3. `$city` se corresponde con el formato `%-17s`. En este primer caso será el nombre de la ciudad `Abu Dhabi` justificado a la izquierda y después los espacios en blanco necesarios hasta llegar a la posición `17`. El número `17` viene del número de posiciones del nombre de la ciudad más larga que es `Ciudad de Mexico` más un espacio a la derecha para permitir la separación mínima entre columnas.

De esta forma cada columna del menú ocupa exactamente `20` posiciones necesarias para mantener la alineación de las columnas del menú: 
* Dos posiciones para el número de la ciudad justificado a la derecha
* Una posición para el espacio que separa el número del nombre de la ciudad
* 17 posiciones para el nombre de la ciudad más larga justificada a la izquierda incluyendo un espacio a la derecha

---

Una vez que hemos colocado en `$menu` y en su columna correspondiente el número y nombre de ciudad con el ancho fijo de 20 posiciones que hemos visto necesitamos saber si nos encontramos en la cuarta columna para pintar un salto de línea en `$menu`:
```raku
if $city-number == $last-col {
    $menu ~= "\n";
    $last-col += $menu-cols;
}
```
Si el número de ciudad `$city-number` es igual `==` a la última columna de la línea `$last-col`, que originalmente es `4` ocurrirán dos cosas:
* En `$menu` agregamos `~=` un salto de línea `"\n"`
* Incrementamos `$last-col`, que originalmente tiene `4`, con el número de columnas `$menu-cols` que son precisamente `4` utilizando el operador de adición junto con igual `+=` 

De esta forma siempre daremos un salto de línea después de colocar la cuarta ciudad en una línea del menú. En caso contrario, si `$city-number` no se corresponde con algún número de `$last-col`, pues no se ejecuta esta condición y pintaremos la siguiente ciudad a continuación de la línea actual.

Por último, incrementamos el número de ciudad para tenerlo en cuenta en la siguiente vuelta con la siguiente ciudad:

```raku
$city-number++;
```
Aquí finaliza el bucle de creación del hash `%cities-lat-lon-sorted` y del `$menu`.

## Visualizando y utilizando el menú

Ya tenemos el `$menu` con todas las ciudades y su número correspondiente en cuatro columnas alineadas. Ahora lo visualizaremos dentro de un bucle mostrando al usuario un mensaje para que elija una ciudad e introduzca su número para obtener su temperatura actual.

Cuando el usuario introduzca un número, lo dejaremos en la variable `$op` y si se trata de un número comprendido en el rango permitido de las ciudades realizaremos las siguientes operaciones:

* Le daremos `$op` al hash `%cities-lat-lon-sorted` para obtener la latitud y la longitud de la ciudad correspondiente
* Con la latitud y la longitud construiremos la URL correspondiente de `api.open-meteo.com` y la utilizaremos con la función `get-url` para descargar la respuesta que contiene la temperatura
* De la información descargada, buscaremos en ella los grados de temperatura y la mostraremos por pantalla

Para salir del bucle y de la aplicación indicaremos al usuario que introduzca un número distinto de cualquier ciudad. Este es el código restante:

```raku
shell 'clear';
$menu.say;

my $prompt-message = "\nEnter city number to show the current temperature. Another number = exit: ";
my $op = prompt $prompt-message;

# menu loop
while $op >= 1 and $op <= %cities-lat-lon-sorted.elems {

    my $city      = %cities-lat-lon-sorted{$op}<city>;
    my $latitude  = %cities-lat-lon-sorted{$op}<latitude>;
    my $longitude = %cities-lat-lon-sorted{$op}<longitude>;

    my $url-temperature = "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true";

    my $temperature = get-url($url-temperature) ~~ /\"temperature\"\:<( \-? \d+ [\. \d+]? )>/;

    shell 'clear';
    "$menu\n".say;

    "       City: $op $city".say;
    "Temperature: $temperature °C".say;

    $op = prompt $prompt-message;
}
```

Como vemos en el código, antes de llegar al bucle necesitamos, primero, dejar limpia la pantalla del terminal, visualizar por primera vez el menú y pedir al usuario un número de ciudad:
```raku
shell 'clear';
$menu.say;

my $prompt-message = "\nEnter city number to show the current temperature. Another number = exit: ";
my $op = prompt $prompt-message;
```
La variable `$op` utiliza `prompt` para mostrar el mensaje `$prompt-message`, esto es, esperar al usuario a que introduzca algo por teclado y lo dejará en `$op`. 

Veamos ahora las condiciones para entrar en el bucle:
```raku
while $op >= 1 and $op <= %cities-lat-lon-sorted.elems {
```
El bucle utiliza `while` mientras `$op` esté comprendido entre 1 y el número de elementos del hash ordenado `%cities-lat-lon-sorted.elems`. Si el usuario ha introducido en `$op` algo distinto, ignora el bucle y la aplicación termina.

Dentro del bucle obtendremos el nombre de la ciudad `$city`, la latitud `$latitude` y la longitud `$longitude` utilizando `$op` como clave del hash `%cities-lat-lon-sorted`:
```raku
my $city      = %cities-lat-lon-sorted{$op}<city>;
my $latitude  = %cities-lat-lon-sorted{$op}<latitude>;
my $longitude = %cities-lat-lon-sorted{$op}<longitude>;
```    

Después construimos la URL `$url-temperature` utilizando `$latitude` y `$longitude`:
```raku
my $url-temperature = "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true";
```
Esta URL es la misma que nos devolvería la web como vimos en la primera parte al clicar en una ciudad, la información climática y el botón `Preview`. Solo queda descargar el contenido JSON de esta URL mediante la función `get-url` y obtener la temperatura. Todas estas operaciones las realizaremos con una sola línea de código:
```raku
my $temperature = get-url($url-temperature) ~~ /\"temperature\"\:<( \-? \d+ [\. \d+]? )>/;
```
Aquí vemos el operador smartmatch `~~` que se utiliza para proporcionar un texto a su izquierda y buscar en él un token a su derecha que va entre barras. Además y en este caso, el token utiliza las marcas de captura `<(` y `)>` indicando la captura de la temperatura. 

El token comienza con el texto `\"temperature\"\:` que realmente representa el texto `"temperature":`. Esto es así porque no es un token como el de una gramática, y tanto las comillas dobles como los dos puntos están escapados con la barra invertida. 

A continuación indicamos la captura de la temperatura `<( \-? \d+ [\. \d+]? )>`. Entre las marcas de captura `<(` y `)>` se encuentra el token de un número que puede ser negativo y decimal, como algunos tokens de las gramáticas que vimos anteriormente. 

Si este token se encuentra en el JSON descargado por `get-url($url-temperature)`, el número de la temperatura quedará disponible en `$temperature`.

Como ejemplo, así es el texto descargado para la ciudad de Madrid en este momento:
```
HTTP/1.1 200 OK
Date: Mon, 02 May 2022 14:37:14 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 234
Connection: close

{"utc_offset_seconds":0,"latitude":40.4375,"current_weather":{"temperature":17,"time":"2022-05-02T14:00","windspeed":6.2,"weathercode":80,"winddirection":6},"longitude":-3.6875,"generationtime_ms":0.5860328674316406,"elevation":644.5}
```
Como vemos, la temperatura es el número `17` expresado de forma única dentro de `"temperature":17`, y el token `/\"temperature\"\:<( \-? \d+ [\. \d+]? )>/` captura ese `17` dejándolo en `$temperature`.

## Mostrando la temperatura
Ya hemos cumplido la parte más complicada del objetivo de la aplicación que es obtener la temperatura actual de una ciudad elegida por el usuario, ahora se la mostraremos :
```raku
shell 'clear';
"$menu\n".say;

"       City: $op $city".say;
"Temperature: $temperature °C".say;
```
Las dos primeras líneas limpian la pantalla y muestran el `$menu`. Esto es necesario para ofrecer al usuario nuevamente la posibilidad de elegir otra ciudad.

Después mostramos la ciudad precedida de su número `$op $city` y por último mostramos su temperatura actual indicando el sufijo de grados centígrados.

Finalmente, solo queda volver a preguntar al usuario si quiere la temperatura de otra ciudad o salir de la aplicación con:
```raku
$op = prompt $prompt-message;
```
En este punto concluye el bucle `while` con su cierre de llave `}` y la aplicación.

El código final de la aplicación en el archivo `ElTiempo.raku` es el siguiente:
```raku
use lib 'lib';
use GetURL;

my $url = 'https://open-meteo.com/en/docs';
my $url-content = get-url($url);

grammar OPTION-CITIES {

    token TOP {
        <option-open> <latitude> <longitude> <data-asl> <city> <option-close>
    }
    token option-open {
        \s* ['<option ' | '<option selected ']
    }
    token latitude       { <latitude-name> <latitude-value> }
    token latitude-name  { 'data-latitude="' }
    token latitude-value { <number> }
    token number {
        \-?\d+ [\. \d+]?
    }
    token longitude       { <longitude-name> <longitude-value> }
    token longitude-name  { '" data-longitude="' }
    token longitude-value { <number> }
    token data-asl {
        '" data-asl="'<number>'">'
    }
    token city { <[ a..z A..Z \s ]> ** 3..40 }
    token option-close { '</option>' }
}

my %cities-lat-lon = gather for $url-content.lines -> $line {

    next unless my $match = OPTION-CITIES.parse($line);

    take $match.<city> => {
        'latitude'  => $match.<latitude><latitude-value>,
        'longitude' => $match.<longitude><longitude-value>
    }
}

my $menu        = "\n";
my $menu-cols   = 4;
my $last-col    = $menu-cols;
my $city-number = 1;

my %cities-lat-lon-sorted = gather for %cities-lat-lon.sort(*.key)>>.kv -> ($city, $data) {

    take $city-number => {
        'city'      => $city,
        'latitude'  => $data.<latitude>,
        'longitude' => $data.<longitude>
    }

    $menu ~= sprintf "%2s %-17s", $city-number, $city;

    if $city-number == $last-col {
        $menu ~= "\n";
        $last-col += $menu-cols;
    }

    $city-number++;
}

shell 'clear';
$menu.say;

my $prompt-message = "\nEnter city number to show the current temperature. Another number = exit: ";
my $op = prompt $prompt-message;

# menu loop
while $op >= 1 and $op <= %cities-lat-lon-sorted.elems {

    my $city      = %cities-lat-lon-sorted{$op}<city>;
    my $latitude  = %cities-lat-lon-sorted{$op}<latitude>;
    my $longitude = %cities-lat-lon-sorted{$op}<longitude>;

    my $url-temperature = "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true";

    my $temperature = get-url($url-temperature) ~~ /\"temperature\"\:<( \-? \d+ [\. \d+]? )>/;

    shell 'clear';
    "$menu\n".say;

    "       City: $op $city".say;
    "Temperature: $temperature °C".say;

    $op = prompt $prompt-message;
}
```

## Epílogo
Ya hemos llegado al final de esta serie de posts donde hemos desarrollado una aplicación de línea de comandos en Linux para obtener la temperatura actual de una ciudad.

También hemos aprendido varias cosas interesantes de `Raku` para:
* Realizar conexiones HTTP de forma asíncrona y concurrente para obtener información de un origen remoto
* Reutilizar funciones mediante módulos y crear la estructura de una aplicación
* Utilizar gramáticas para validar y obtener información de forma precisa
* Crear y utilizar hashes para guardar y recuperar rápidamente información
* Interaccionar con el usuario mediante un menú de texto
