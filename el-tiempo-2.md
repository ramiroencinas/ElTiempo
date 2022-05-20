# Parte 2 - Preparación del entorno
En la parte anterior vimos varias cosas:
* Cómo la web https://open-meteo.com/en/docs puede generar una URL para obtener información climática de una ciudad
* El planteamiento de la aplicación que vamos a desarrollar para averiguar la temperatura de una ciudad
* La necesidad de disponer de las ciudades y sus coordenadas, obteniendo esta información a partir del código HTML de https://open-meteo.com/en/docs

Ahora veamos los pasos que seguirá la aplicación que vamos a desarrollar:

1. Conectar con https://open-meteo.com/en/docs y descargar su código HTML
2. Del código HTML anterior, extraer las ciudades, latitudes y longitudes correspondientes y guardar esta información en un hash
3. Utilizando el hash anterior construir un menú con las ciudades
4. Mostrar el menú de las ciudades, de forma que cuando el usuario elija una ciudad, obtener la latitud y la longitud correspondiente del hash
7. Construir la URL con la latitud y la longitud obtenida del hash de la ciudad elegida
8. Conectar a la URL construida y obtener el JSON con la información de la temperatura
9. Extraer la información de la temperatura del JSON y mostrarla al usuario

Ya es momento de empezar a programar, elegir un lenguaje de programación y un entorno de desarrollo. Para facilitar la compresión a partir de este punto, te recomiendo tener nociones sobre algún lenguaje de programación interpretado y también conocimientos elementales de la línea de comandos con GNU/Linux. 

## El entorno de desarrollo
Para realizar el desarrollo de esta aplicación utilizaremos cualquier distribución GNU/Linux y el lenguaje de programación [Raku](https://www.raku.org). Si bien `Raku` tiene muchos aspectos potentes e interesantes, en las líneas de código que veremos después apreciaremos su efectividad y elegancia visual, así como su potencia en cuanto a extracción y tratamiento de información. Para empezar con `Raku` te recomiendo [la guía de introducción](https://raku.guide/es/). La forma más sencilla de instalar `Raku` en las distribuciones GNU/Linux más conocidas es utilizando los paquetes precompilados `rakudo-pkg` cuyas indicaciones están en [este sitio](https://nxadm.github.io/rakudo-pkg/). Una vez instalado `Raku` es necesario también instalar el gestor de módulos `zef` siguiendo [estas indicaciones](https://nxadm.github.io/rakudo-pkg/docs/zef.html). Utilizaremos `zef` para instalar un módulo necesario para la aplicación.

## Un cliente web con Raku
Primero necesitamos una función básica que implemente un cliente web, de forma que le proporcionaremos una URL y descargará su contenido, como hace cURL pero de forma más elemental. Esta función la utilizaremos en los puntos 1 y 6 de los pasos que vimos antes.

Para desarrollar esta función utilizaremos dos potentes funcionalidades: 
1. `Gramáticas` para trocear la URL y extraer las partes que necesitaremos después para realizar la conexión web 
2. El módulo `IO::Socket::Async::SSL` para facilitar la conexión web en sí. Antes de continuar es necesario instalar este módulo con `zef` utilizando la línea de comandos:
```
zef install IO::Socket::Async::SSL
```

### Preparando una conexión web

La primera web a la que vamos a conectar, como vimos anteriormente, tiene la siguiente dirección o URL: 

`https://open-meteo.com/en/docs`
 
esta URL se compone de tres partes:

- `https://` es el prefijo del protocolo de transferencia segura de hipertexto
- `open-meteo.com` el dominio del sitio web, también denominado `host`
- `/en/docs` la ruta donde se encuentra la web en sí, y lo denominaremos `resource-path`

Es importante saber que una URL al menos debe comenzar con el prefijo `https://` seguido del dominio `host`, pero la ruta `resource-path` es opcional. Cuando una URL no tiene `resource-path` como por ejemplo en `https://open-meteo.com` el `resource-path` es la raíz o barra `/`. Este detalle lo tendremos en cuenta.

Para construir una solicitud HTTPS necesitamos extraer el `host` y el `resource-path` de la URL. Para ello utilizaremos una `gramática`.

### Descomponiendo y validando una URL con una gramática

Una gramática se declara con la palabra clave `grammar` y un nombre para identificarla. Como lo que vamos a hacer es descomponer una URL para extraer sus trozos, pues le ponemos ese mismo nombre `URL`. El funcionamiento de la gramática viene después entre llaves, de forma parecida a una función:

```raku
grammar URL {
  ...
}
```

Entre las llaves de nuestra gramática `URL` indicaremos los nombres de los distintos trozos de los que se compone una URL para después disponer de ellos. Como vimos antes, al menos esta URL se compone de dos trozos: `protocol` y `host`, mientras que un tercer trozo `resource-path` es opcional. Ahora pondremos los nombres de estos tres trozos en el `token` principal `TOP` de la siguiente forma:

```raku
grammar URL {
  token TOP { <protocol> <host> <resource-path> ? }
  ...
}
```

El token `TOP` es obligatorio, y en él podemos indicar nombres entre los símbolos `< >` que se corresponderán con algunas expresiones regulares que definiremos después. El símbolo de interrogación a la derecha del token `<resource-path>` quiere decir que `<resource-path>` es opcional.

Debajo definimos el token `protocol` indicando su expresión regular:

```raku
grammar URL {
  token TOP      { <protocol> <host> <resource-path> ? }
  token protocol { 'https://' }
  ...
}
```
Entre las llaves del token `protocol` indicamos el protocolo https que siempre es el mismo, esto es `'https://'`. Va entre comillas simples para que se interprete literalmente, caracter por caracter, tal cual. 

El siguiente token es `<host>` y se trata del nombre de un dominio. En la primera conexión se trata de `open-meteo.com` y en la segunda conexión se trata de `api.open-meteo.com` por lo que podemos decir que este trozo es un texto que incluye letras minúsculas, puntos y guiones medios. Para ser un poco más flexibles podemos indicar que incluya además, números y guiones bajos. Además, es conveniente indicar el número mínimo y máximo permitido de caracteres, por ejemplo entre 3 y 40 caracteres. Todo esto podemos hacerlo fácilmente al estilo `Raku` con la siguiente expresión regular:

`<[ a..z 0..9 _ . - ]> ** 3..40`

Lo que hay entre la apertura `<[` y el cierre `]>` son los caracteres permitidos que puede contener el texto:

- `a..z` es cualquier letra minúscula
- `0..9` es cualquier número
- `_` guión bajo
- `.` punto
- `-` guión medio

Después, los dos asteriscos y el rango `** 3..40` indican que el texto del nombre de dominio debe tener entre 3 y 40 caracteres. Agregamos este token `host` a la gramática:

```raku
grammar URL {
  token TOP      { <protocol> <host> <resource-path> ? }
  token protocol { 'https://' }
  token host     { <[ a..z 0..9 _ . - ]> ** 3..40 }
}
```

El último token es `resource-path` y es opcional. Como vimos antes, un ejemplo puede ser `/en/docs`, pero puede ser más largo e incluir un número indeterminado de parámetros. Siempre comienza con una barra `/` y sigue hasta el final de la URL. Este trozo necesita admitir, además de letras y números, más símbolos como `?`, `=` y `&`. Estos símbolos sirven para identificar a los distintos parámetros y valores que puede tener una URL.

También aquí es recomendable determinar un número máximo de caracteres, como por ejemplo 255. Este token `resource-path` queda incluido al final de la gramática, finalizando con el cierre de llave:

```raku
grammar URL {
  token TOP           { <protocol> <host> <resource-path> ? }
  token protocol      { 'https://' }
  token host          { <[ a..z 0..9 _ . - ]> ** 3..40 }
  token resource-path { '/' <[ a..z 0..9 / ? = & _ . - ]> ** 1..255 }   
}
```

Como vemos, el token `resource-path` comienza con una barra `'/'` seguida de los caracteres permitidos entre `<[` y `]>`, que son letras minúsculas, números, barras `/`, símbolos de interrogación `?`, igual `=`, ligadura `&`, guión bajo `_`, punto `.` y guión medio `-`. A la derecha de los caracteres permitidos indicamos la longitud mínima `1` y máxima `255` permitida. Es un requisito básico de seguridad indicar el número mínimo y máximo de caracteres permitidos y cuales son, y `Raku` lo hace muy fácil.

En este punto ya podemos proporcionar una URL a la gramática y extraer de ella al menos el `host` y el `resource-path` si existiera. Para ello, proporcionaremos la URL en la variable `$url` como parámetro al método `parse` de la gramática `URL`, dejando el resultado en `$m`:

```raku
unless my $m = URL.parse($url) { return 'Bad URL'; }
```

Si no se cumplen los requisitos de la gramática, `unless` hace que se ejecute la parte entre las llaves, esto es, salir de la función actual devolviendo el mensaje de error indicando que la URL proporcionada no es válida: `Bad URL`.

Si todo va bien, la nueva variable `$m` contiene los resultados de `host` y `resource-path` en forma de propiedades accesibles de la siguiente manera:

```raku
$m.<host>
$m.<resource-path>
```

### Un par de ingredientes más

Para continuar con la conexión necesitamos dos variables más para indicar el puerto remoto `443`, utilizado por defecto en las conexiones SSL y la versión HTTP, donde en este caso utilizaremos la `1.0`:

```raku
my $remote-port  = 443;
my $http-version = 'HTTP/1.0';
```

### Preparación de la conexión

Ya tenemos toda la información necesaria para realizar la conexión a la URL proporcionada. Para ello utilizaremos el módulo que instalamos antes con `zef` de la siguiente forma:

```raku
use IO::Socket::Async::SSL;
```

Y declaramos la conexión `$conn` proporcionando el `$m.<host>` y el puerto remoto `$remote-port` como parámetros:

```raku
my $conn = await IO::Socket::Async::SSL.connect($m.<host>, $remote-port);
```

Lo que devuelve `IO::Socket::Async::SSL` en `$conn` es una `promesa`. Una `promesa` es una funcionalidad utilizada en `programación concurrente` que permite utilizar el resultado de un proceso antes de que este resultado esté disponible. La palabra clave `await` que precede a `IO::Socket::Async::SSL` dejará en `$conn` el resultado cuando esté disponible.

### Creando una solicitud HTTP

Utilicemos ahora la promesa `$conn` para crear una solicitud HTTP y enviarla al servidor remoto:

```raku
$conn.print: "GET $m.<resource-path> $http-version\r\nHost: $m.<host>\r\n\r\n";
```

El método `.print` envía a través de la conexión `$conn` el texto de la cabecera de una solicitud HTTP y va entre comillas dobles `"` para que los valores de las variables que contiene se sustituyan por sus valores reales. Expliquemos cada parte de la que se compone esta solicitud HTTP:

- `GET`: es un método HTTP que sirve para realizar una solicitud de un recurso a una página web
- `$m.<resource-path>`: es la ruta o ubicación de la página web, como vimos antes
- `$http-version`: es la versión HTTP que utilizaremos y definimos antes con el valor `HTTP/1.0`
- `\r\n`: son dos códigos especiales que significan `salto de línea`, se compone de `\r` retorno de carro y `\n` línea nueva
- `Host: $m.<host>`: indica nuevamente el host o dominio remoto
- `\r\n\r\n`: como vimos antes, pero en este caso son dos saltos de línea. Esto deja una línea en blanco y significa que finaliza la cabecera HTTP

Para la primera URL `https://open-meteo.com/en/docs` y una vez sustituidos los valores de las variables, la cabecera HTTP correspondiente quedaría así:

```
GET /en/docs HTTP/1.0
Host: open-meteo.com
(línea en blanco)
```
### Obteniendo el resultado

Primero definimos una variable vacía para alojar el resultado:
```raku
my $resultado = '';
```

Para obtener el resultado de una promesa como `$conn` utilizamos las palabras clave `react` y `whenever` de la siguiente forma:

```raku
react {
  whenever $conn -> $buffer {
    $resultado ~= $buffer;
  }
}
```
En Raku utilizamos `react` para *reaccionar* cuando llega información de una promesa. Dentro de las llaves de `react` la palabra clave `whenever` utiliza la promesa `$conn` para ir recogiendo los trozos `$buffer` que van llegando y los va agregando `~=` en el `$resultado` hasta que llega el último trozo.

Por último, cerramos la promesa:
```raku
$conn.close;
```

## Probando el cliente web en un script de Raku

Vamos a probar todas estas líneas de código `Raku` que hemos visto. En un fichero de texto denominado `web-client.raku` vamos a incluir el código que hemos desarrollado para el cliente web en una función denominada `get-url`. A esta función le proporcionaremos una `$url` de ejemplo cuyos parámetros incluyen las coordenadas de Madrid y la información actual del clima:

```raku
my $url = 'https://api.open-meteo.com/v1/forecast?latitude=40.4167&longitude=-3.7033&current_weather=true';

get-url($url).say;

sub get-url ($url) {

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

En una misma línea de código `get-url($url).say;` llamamos a la función `get-url` con el parámetro `$url` y mostramos el resultado de una forma elegante con el método `.say`.

El script lo ejecutamos con `raku get-url.raku` y si todo va bien obtendremos la respuesta HTTP del servidor remoto, que en mi caso ha sido:

```
HTTP/1.1 200 OK
Date: Mon, 07 Mar 2022 20:54:05 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 237
Connection: close

{"generationtime_ms":0.12302398681640625,"elevation":644.5,"utc_offset_seconds":0,"current_weather":{"windspeed":4.9,"winddirection":137,"time":"2022-03-07T20:00","weathercode":3,"temperature":7.5},"latitude":40.4375,"longitude":-3.6875}
```

Las primeras cinco líneas representan la cabecera de la respuesta HTTP enviada por el servidor web, proporcionando la información de estado de la respuesta. Después viene una línea en blanco y después viene la línea con el cuerpo de la respuesta en sí en formato JSON, incluyendo la información que buscamos. Si bien esta es la información *en bruto*, después es necesario filtrarla para obtener la temperatura, operación que veremos más adelante.

Ya tenemos una función básica de conexión que utilizaremos en los pasos 1 y 8 que vimos al principio de esta parte. En la [Parte 3](el-tiempo-3.md) profundizaremos en el paso 1 utilizando esta función para conectar con la web `https://open-meteo.com/en/docs` y obtener las ciudades y sus coordenadas.
