## Uso de módulos, estructura y ciudades con sus coordenadas

En la parte anterior desarrollamos en `Raku` una función básica denominada `get-url` para conectar y descargar el código HTML de una web mediante SSL. Esta función vamos a utilizarla con la URL `https://open-meteo.com/en/docs`. Descargado el contenido, lo analizaremos para obtener la información que relaciona las ciudades y sus coordenadas.

### Un módulo para la función get-url

Un código fácil de leer y de revisar separa el código principal de otras partes del código que realizan una tarea concreta más de una vez. Estas otras partes son funciones y su código va colocado en otros ficheros denominados librerías o `módulos` en el caso de `Raku`. Así, desde el código principal podemos cargar estos módulos (librerías) y utilizarlos las veces necesarias despejando el código principal.

Para crear un nuevo módulo con la función `get-url`, primero es necesario disponer de una estructura de carpetas y ficheros para la aplicación. Para comenzar, creamos una carpeta principal para la aplicación, denominada `ElTiempo`. Dentro de esta carpeta creamos otra carpeta denominada `lib` donde alojaremos los ficheros de módulos o librerías y dentro de esta carpeta creamos un nuevo fichero denominado `GetURL.rakumod` que contendrá el código de un módulo de `Raku`, concretamente el de la función `get-url` que vimos en la parte anterior, pero ligeramente adaptado. El código de `GetURL.rakumod` es el siguiente:

```raku
unit module GetURL;

sub get-url ($url) is export {

    grammar URL {

        token TOP              { <protocol> <host> <resource-path>? }
        token protocol         { 'https://' }
        token host             { <[ a..z 0..9 _ . - ]> ** 5..40 }
        token resource-path    { '/' <[ a..z 0..9 / ? = & _ . - ]> ** 1..255 }
    }

    unless my $m = URL.parse($url) { return 'Bad URL'; }

    my $remote-port  = 443;
    my $http-version = 'HTTP/1.0';

    use IO::Socket::Async::SSL;
    my $conn = await IO::Socket::Async::SSL.connect($m.<host>, $remote-port);
    $conn.print: "GET $m.<resource-path> $http-version\r\nHost: $m.<host>\r\n\r\n";

    my $result = '';

    react {
        whenever $conn -> $buffer {
            $result ~= $buffer;
        }
    }

    $conn.close;

    return $result;
}
```

El módulo comienza con `unit module GetURL;`, donde `GetURL` es el nombre del módulo. Más abajo aparece la definición de la función `get-url` incluyendo `is export` para que la función quede disponible después de cargar el módulo `GetURL` desde el código principal.

El código principal de la aplicación se incluye en el fichero denominado `ElTiempo.raku` ubicado en la carpeta principal de la aplicación `ElTiempo` que hemos creado antes. La estructura de carpetas y ficheros de momento quedará así:

```
📁 ElTiempo
  📄 ElTiempo.raku
  📁 lib
    📄 GetURL.rakumod
```

El código del script principal de la aplicación `ElTiempo.raku`, de momento es el siguiente:

```raku
use lib 'lib';
use GetURL;

my $url = 'https://api.open-meteo.com/v1/forecast?latitude=40.4167&longitude=-3.7033&current_weather=true';

get-url($url).say;
```

Lo primero que le decimos a la aplicación es la ubicación de la carpeta donde encontraremos los módulos o librerías mediante `use lib 'lib';`. Como esta carpeta se encuentra en la misma carpeta del script principal, se escribe el nombre de la carpeta tal cual entre comillas simples. Después, con `use GetURL;` indicamos el nombre del módulo que necesitamos utilizar. El nombre del módulo se corresponde con el prefijo del nombre del fichero del módulo `GetURL.rakumod` ubicado en la carpeta `'lib'`. De esta forma, la función `get-url` que está dentro del fichero `GetURL.rakumod` quedará disponible en este script.

Ya tenemos una estructura básica y operativa de la aplicación. Desde la línea de comandos vamos a la carpeta `ElTiempo` y ejecutamos la aplicación con:

```raku Eltiempo.raku```

Si todo es correcto aparecerá una respuesta similar a la que vimos antes, cuando ejecutamos la función `get-url` directamente.

### Buscando ciudades y coordenadas

Adaptemos el código de `Eltiempo.raku` para descargar el código HTML de la web donde se encuentra la información de ciudades y coordenadas cuya URL es `https://open-meteo.com/en/docs`, y guardemos el código HTML descargado en el fichero `open-meteo.html`:

```raku
use lib 'lib';
use GetURL;

my $url = 'https://open-meteo.com/en/docs';

my $url-content = get-url($url);

spurt 'open-meteo.html', $url-content;
```

Ejecutamos con:

```
raku Eltiempo.raku
```

Abrimos `open-meteo.html` con un editor de texto y sobre la línea 118 encontramos el comienzo de la información que buscamos:

```html
<option selected data-latitude="52.5235" data-longitude="13.4115" data-asl="34">Berlin</option>
<option data-latitude="48.8567" data-longitude="2.3510" data-asl="34">Paris</option>
...
```

En cada línea aparece la ciudad entre las etiquetas HTML `option` `<option ... > Nombre de ciudad </option>`, y dentro de cada etiqueta `option` la latitud como valor del atributo `data-latitude="número indicando la latitud"` y la longitud como valor del atributo `data-longitude="número indicando la longitud"`. 

Si nos fijamos en la primera línea de las que hemos encontrado, vemos que comienza con `<option selected data-latitude...` y el resto de líneas con `<option data-latitude...`, esto es, la primera línea incluye el atributo `selected` entre `<option` y `data-latitude` y el resto de estas líneas no incluye este atributo. Este detalle es importante y es necesario tenerlo en cuenta.

También vemos en todas las líneas la existencia del atributo `data-asl`, pero no aporta nada.

### Obteniendo ciudades y coordenadas con una gramática

Sabemos que en el código HTML descargado existen líneas entre etiquetas `<option ... > ... </option>` que contienen una ciudad y sus coordenadas. También conocemos los elementos que tiene cada una de estas líneas. Pongamos estos elementos que pertenecen a una línea en la gramática `OPTION-CITIES`, en el token `TOP`:

```raku
grammar OPTION-CITIES {

  token TOP {
    <option-open> <latitude> <longitude> <data-asl> <city> <option-close>
  }
    
}
```

Después del token `TOP` definimos cada uno de sus elementos en su propio token, comenzando con el inicio de la etiqueta `<option...`:

```raku
token option-open {

  \s* ['<option ' | '<option selected ']

}
```

El token `option-open` comienza en el inicio de una línea. La expresión regular `\s*` tiene en cuenta los espacios que hay al principio de la línea, si existen. El término `\s` representa un espacio y `*` significa ninguno, uno o más de uno de lo que hay a la izquierda. Por tanto indicar `\s*` al principio de una línea sirve para detectar si la línea no comienza con ningún espacio o si comienza con un número indeterminado de ellos. Esto es importante y es necesario para tener la precisión adecuada al detectar los siguientes elementos de la línea. 

Después busca si aparece el texto `<option` o `<option selected`. De esta forma detectamos la primera línea que, recordemos, comienza con `<option selected data-latitude` y también detectamos el resto de líneas que comienzan con `<option data-latitude`. Como vemos, las dos opciones figuran entre corchetes `['<option ' | '<option selected ']` separadas del operador lógico `OR` representado con una barra vertical o tubería.

Seguimos con el siguiente token `<latitude>` formado por dos token más: `<latitude-name>` para el nombre y `<latitude-value>` para el valor:

```raku
token latitude       { <latitude-name> <latitude-value> }
token latitude-name  { 'data-latitude="' }
token latitude-value { <number> }
```

El token `latitude-name` contiene el texto en sí entre comillas simples según viene en el código HTML descargado incluyendo hasta el símbolo igual y las dobles comillas.

El token `latitude-value` es el valor que realmente necesitamos; es un dígito que puede ser un número decimal con signo, definido en su token correspondiente a continuación justo debajo:

```raku
token number {

  \-?\d+ [\. \d+]?
  
}
```

Aquí utilizamos una expresión regular indicando que:
- Puede comenzar con un símbolo menos o no `\-?`
- Seguido de un dígito o más de uno `\d+`
- Después indicamos la parte decimal, que es opcional, entre corchetes seguido de una interrogación. Dentro de los corchetes la parte decimal comienza con un punto `\.` y un dígito o más de uno `\d+`.

Como vemos, en el contexto de expresiones regulares, la barra invertida o backslash sirve para indicar símbolos textuales como el punto o el guión medio y también para denotar un comodín para un dígito o número `\d`. La interrogación significa uno o ninguno de lo que hay a la izquierda y el símbolo `+` significa uno o más de uno de lo que hay a la izquierda.

El token `longitude` y los tokens que lo componen son similares al del token `latitude`:

```raku
token longitude       { <longitude-name> <longitude-value> }
token longitude-name  { '" data-longitude="' }
token longitude-value { <number> }
```

Como vemos, reutilizamos el token `number` ya definido anteriormente.

El token `data-asl` es sencillo:

```raku
token data-asl {

  '" data-asl="'<number>'">'
  
}
```
Este token solo sirve para saber que este texto está ahí, ocupando el espacio que hay entre lo que tiene a su izquierda y a su derecha, identificando de una forma muy precisa estas líneas.

Cuidado con las combinaciones múltiples de comillas simples y dobles. Dentro de cada par de comillas simples va el texto tal cual incluyendo comillas dobles.

El token de la ciudad solo permitirá letras minúsculas y mayúsculas y espacios `\s` con un total de entre 3 y 40 caracteres:

```raku
token city { <[ a..z A..Z \s ]> ** 3..40 }
```

Por último, cerramos con el token `option-close`, literalmente el texto de cierre de la etiqueta HTML `option` entre comillas simples:

```raku
token option-close { '</option>' }
```

Ya tenemos la gramática lista, ahora crearemos un `hash` denominado `%cities-lat-lon` donde introduciremos en él cada ciudad con sus coordenadas correspondientes por cada línea que encaje con la gramática. Dentro del hash, cada clave será una ciudad y el valor serán dos valores, uno para la latitud y otro para la longitud:

```raku
my %cities-lat-lon = gather for $url-content.lines -> $line {

  next unless my $match = OPTION-CITIES.parse($line);

  take $match.<city> => {
    'latitude'  => $match.<latitude><latitude-value>,
    'longitude' => $match.<longitude><longitude-value>
  }
}
```

Construimos este hash directamente con el uso de `gather` y `take`, de forma que `gather` *recoge* lo que viene del `for`, que son las líneas del código HTML descargado `$url-content` con el método `.lines` dejando cada una `->` en la variable `$line`. Entre las llaves se ejecuta el código por cada línea `$line` del código HTML descargado.

Este código comienza con

```raku
next unless my $match = OPTION-CITIES.parse($line);
```

simplemente ignora la línea actual y salta `next` a la siguiente línea si la gramática no encaja `unless` con la línea actual `OPTION-CITIES.parse($line)`. Si encaja, los elementos de la gramática se quedarán en la variable `$match`.

En este punto tenemos en `$match` los elementos de los que se compone cada línea y que definimos en la gramática con los token correspondientes. Para obtener la ciudad utilizamos `$match.<city>` y para obtener la latitud de la ciudad utilizamos `$match.<latitude><latitude-value>`. Como vemos, la información que necesitamos de cada línea es accesible mediante el uso de los nombres de los distintos tokens.

Finalmente `take` devuelve el hash, formado aquí mismo con los valores de los elementos obtenidos:

```raku
take $match.<city> => {
  'latitude'  => $match.<latitude><latitude-value>,
  'longitude' => $match.<longitude><longitude-value>
}
```

La clave de cada elemento del hash `%cities-lat-lon` es la ciudad `$match.<city>` mientras que el valor correspondiente se indica `=>` entre llaves. Dentro de estas llaves indicamos dos hashes más (sin nombre) entre una coma, donde el primero tiene como clave el texto `'latitude'` entre comillas simples y como valor el de la latitud obtenido de la gramática y el segundo de forma similar para la longitud. 

Por último, vamos a probar el funcionamiento del hash con la ciudad `Madrid`:

```raku
my $city = 'Madrid';
"  Ciudad: $city".say;
" Latitud: %cities-lat-lon{$city}<latitude>".say;
"Longitud: %cities-lat-lon{$city}<longitude>".say;
```

Si todo es correcto, ejecutamos la aplicación con `raku ElTiempo.raku` y veremos lo siguiente:

```
  Ciudad: Madrid
 Latitud: 40.4167
Longitud: -3.7033
```

Quedando el código principal en el fichero `ElTiempo.raku` de la siguiente forma:

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

my $city = 'Madrid';
"  Ciudad: $city".say;
" Latitud: %cities-lat-lon{$city}<latitude>".say;
"Longitud: %cities-lat-lon{$city}<longitude>".say;
```
Hemos llegado al final de esta tercera parte donde hemos visto varias cosas interesantes:
* Creación de una estructura para una aplicación `Raku`
* Uso de módulos y funciones
* Creación y uso de gramáticas `Raku` para filtrar la información descargada y obtener información precisa
* Creación y uso de un hash para disponer de dicha información

En la siguiente y última parte ampliaremos estos conocimientos de `Raku` desarrollando un menú de ciudades, llevar a cabo los pasos del 3 al 7 y finalizar la aplicación.