# Micro Bank

En este ejercicio el objetivo es aprender a usar algunas herramientas
de desarrollo básicas que nos ofrece el lenguaje y su librería
estándar.

Practicaremos el uso de estas herramientas desarrollando una
aplicación llamada _micro bank_.

Además introduciremos un aspecto del desarrollo software que hemos
descuidado en los ejercicios anteriores, el testing.

## Mix

_Mix_ es la herramienta de constucción que acompaña a elixir. Nos
permite automatizar las tareas típicas de compilar, crear un proyecto,
ejecutar los tests, manejar las dependencias del proyecto, ..., y
configurar tareas específicas de nuestro proyecto.

Estudia la documentación de la herramienta `mix`, crea un proyecto
para el desarrollo del ejercicio y examina los directorios y ficheros
que forman parte del proyecto.

> :warning: No olvides que hay ficheros ocultos. Sobre todo el
> `.gitignore` es espcialmente útil cuando usamos `git`.

> :warning: No olvide consultar la documentación de `iex -S mix`.


## gen\_server

En elixir los procesos servidor son muy habituales. En los ejercicios
anteriores hemos implementado varios y hemos podido comprobar como en
todos el código sigue un patrón común con una parte importante que se
repite. Esto se ha tenido en cuenta en la librería del lenguaje.

Estudia la documentación del behaviour `gen_server` de la librería
estándar e implementa el ejercicio usando dicho behaviour.


## supervisor

El estilo de gestión de errores de elixir es el _let it fail_. Esto
significa que muchas veces un proceso actua como _supervisor_ de otros
procesos, tomando las decisiones oportunas cuando uno de sus
supervisados falla. Al igual que ocurre con los procesos servidores,
un proceso supervisor también suele seguir un patrón común que se ha
tenido en cuenta en la librería estándar.

Estudia la documentación del behaviour `supervisor` de la librería
estándar. Usando dicho behaviour añade un mecanismo de tolerancia a
fallos que reinicie el servidor cuando falle.


## Descripción del micro bank

El micro bank es un servidor sencillo que guarda una lista de
_cuentas_. Cada cuenta indica el nombre de la persona dueña de la cuenta
y el saldo disponible. El servidor ofrece los siguientes servicios:

  - `stop`, para detener el servidor.
  
  - `deposit, who, amount`, deposita la cantidad indicada en la cuenta
    de `who`.

  - `ask, who`, solicita el saldo de la cuenta de `who`.

  - `withdraw, who, amount`, retira la cantidad indicada de la cuenta
    de `who`.



## Testing

Como parte del desarrollo de este ejercicio, implementa estos tests
que validen el comportamiento del servidor:

  - Las secuencias de llamadas válidas devuelven el resultado
    esperado.
  
  - Las secuencias inválidas devuelven el error esperado.
  
Implementa también los tests que validan el funcionamiento del
supervisor:

   - Si el servidor termina abruptamente, el supervisor lanza un
     _nuevo_ proceso servidor.
	 

> :warning: Recuerda que `mix` ya automatiza la ejecución de los
> tests.

> :warning: Examina la documentación de `mix test`. Es importante
> saber cómo influye en el _setup_ y _teardown_ de los tests.

Es imprescindible que los tests sean independientes. En caso contrario
el orden de ejecución de los tests puede cambiar el resultado de los
mismos. Es decir, el _setup_ puede afectar a la ejecución del
siguiente test, y para evitarlo hay que deshacer los cambios en el
_teardown_. Por ejemplo, si arrancamos el servidor en el setup,
tendremos que pararlo en el teardown para que no afecte a los
siguientes tests.

> :warning: El orden de ejecución de los tests puede ser aleatorio.

