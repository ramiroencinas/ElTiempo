# El tiempo

Conocer la temperatura del lugar donde uno se encuentra antes de salir a la calle es importante.

Hay muchas webs y aplicaciones que ofrecen la temperatura y otros datos climáticos de un lugar, pero también y como ejercicio, quería hacer una pequeña aplicación de línea de comandos que conectara con alguna de ellas y proporcionara, por ejemplo, la temperatura actual de un lugar dado. Buscando una web de este tipo encontré una con muy buena pinta: https://open-meteo.com

En esta web, en el apartado de documentación https://open-meteo.com/en/docs puedes elegir una ciudad y seleccionar la información climática que quieras averiguar. Después, al clicar en el botón `Preview` aparece una URL un poco más abajo en la parte denominada `API URL`. Esta URL incluye los parámetros correspondientes a la ciudad y la información climática antes seleccionada, y cuando utilizas esta URL en un navegador web obtienes la información climática correspondiente.

Por ejemplo, en el desplegable `Select city` selecciona `Madrid` como ciudad, deja en blanco todos los checklists de los apartados `Hourly Weather Variables` y `Daily Weather Variables`, en la sección `Settings` activa el control `Current weather with temperature, windspeed and weather code` y un poco más abajo clica en `Preview`, abajo en el apartado `API URL` aparecerá la siguiente URL:

https://api.open-meteo.com/v1/forecast?latitude=40.4167&longitude=-3.7033&current_weather=true

Utilizando esta URL en un navegador web, ahora mismo devuelve el siguiente JSON:
```json
{
    "current_weather":{
        "winddirection":349,
        "temperature":31.6,
        "time":"2022-05-20T18:00",
        "windspeed":4.8,
        "weathercode":3
     },
     "generationtime_ms":0.1380443572998047,
     "longitude":-3.6875,
     "elevation":644.5,
     "latitude":40.4375,
     "utc_offset_seconds":0
}
```
Como vemos, aparecen 31,6 grados centígrados en el campo `temperature`. Ahora mismo para salir a la calle en Madrid, conviene ir en manga corta y bien hidratado.

## Planteamiento
A la aplicación que vamos a desarrollar también le proporcionaremos el nombre de una ciudad para obtener su temperatura, pero analizando la URL que hemos visto después de seleccionar la ciudad de Madrid:
```
https://api.open-meteo.com/v1/forecast?latitude=40.4167&longitude=-3.7033&current_weather=true
```
comprobamos que no incluye el nombre de la ciudad seleccionada (Madrid). Lo que incluye son las coordenadas de Madrid que son: `latitude=40.4167` y `longitude=-3.7033`.

Esta situación produce un problema, pues nuestra aplicación pedirá una ciudad al usuario, no sus coordenadas. Para solucionar este problema es necesario que la aplicación conozca previamente las ciudades y sus coordenadas correspondientes, y cuando esto suceda, estará preparada para pedir una ciudad al usuario, obtener sus coordenadas, utilizarlas para construir una URL como la que hemos visto y finalmente obtener su temperatura actual. 

## Las ciudades y sus coordenadas
Como hemos visto antes en la web https://open-meteo.com/en/docs, puedes elegir una ciudad entre las que aparecen en el desplegable. De esta situación deducimos que la web ya tiene cargada una lista de ciudades y es posible que también vengan las coordenadas de cada una en el código HTML de la página. Buscando en el código HTML de https://open-meteo.com/en/docs vemos que esta información aparece en la parte del código del desplegable de las ciudades, concretamente en las etiquetas `<option>` correspondientes:
```html
<option selected data-latitude="52.5235" data-longitude="13.4115" data-asl="34">Berlin</option>
<option data-latitude="48.8567" data-longitude="2.3510" data-asl="34">Paris</option>
<option data-latitude="51.5002" data-longitude="-0.1262" data-asl="14">London</option>
...
```
Como vemos, cada etiqueta `<option>` tiene las coordenadas de cada ciudad en los atributos `data-latitude` y `data-longitude`.

Llegados aquí, ya tenemos toda la información para plantear la estructura de la aplicación, que veremos en la siguiente parte.