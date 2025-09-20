# Frecuently Recived Feedback

A continuación encontraras una lista de los feedbacks más habituales
que suelen recibir los ejercicios. Asegurate de no aplican a tu
trabajo antes de que el profesor revise tu trabajo.


## **[F01]** Genérico

El `README.md` del repositorio no está actualizado con los datos de
los integrantes del equipo de desarrollo.


## **[F02]** Genérico

Como en cualquier lenguaje funcional, en la medida de lo posible
evitaremos la concatenación de listas.
  
La manera óptima de construir una lista es añadiendo los elementos por
la cabeza.
  
Si no es posible, frente a al opción de usar la concatenación de
listas en cada iteración, en muchos casos será preferible construir la
lista en orden inverso y darle la vuelta al terminar.
  
  
## **[F03]** Genérico

Un elemento importante del lenguaje son los _átomos_. Es habitual
usarlos para representar "valores especiales" como condiciones de
error.
  
En estos casos no debemos usar otros tipos de datos como puedan ser
una lista o una tupla vacía.
  
  
## **[F04]** Genérico

En erlang y exlixir preferimos escribir las funciones como una
secuencia de varias cláusulas, aprovechando la expresividad del
pattern matching.
  
Debemos evitar la forma en que tenemos una única cláusula con un
condicional que determina el caso a aplicar.
  

## **[F05]** Genérico

Las guardas son un elemento más del lenguaje. Resulte extremadamente
útiles para complementar la capacidad del pattern matching.
  
No sólo las podemos usar en las funciones, sino también en otras
expresiones donde usemos patrones, por ejemplo en las expresiones
`receive`.
  
  
## **[F06]** Genérico

La máquina virtual BEAM ya implementa el mecanismo de _ping_ para
monitorizar si el resto de nodos sigue operativo. No debemos volver a
implementarlo. A no ser que podamos hacerlo mucho mejor.
  

## **[F07]** Genérico

La extensión `.exs` está definida para scripts programados en elixir.
El código elixir convencional se escribe en ficheros con extensión
`.ex`.


## **[F-E01]** Eratostenes concurrente

La implementación no se corresponde con lo que se pide en el
enunciado.

Hay que crear un proceso `filtrar_primo` por cada número primo que se
encuentra y cada proceso `filtrar_primo` recibe **un** número de cada
vez y tiene que pasar los números que superan el filtro al siguiente
proceso.  Los procesos filtro sólo conocen el siguiente proceso en la
lista y nunca al proceso padre, tal y como se ilustra en el diagrama
del enunciado.


## **[F-P01]** Pool de trabajadores

La responsabilidad de crear los procesos trabajadores le corresponde
al proceso líder/master.
  
Debes cambiar la implementación para que no se creen dentro del
proceso cliente.
  
  
## **[F-R01]** Gestor de recursos

De esta forma el proceso servidor queda _linkado_ al proceso que llama
a la función `Gestor.start`. Es poco probable que este sea el
comportamiento deseado.


## **[F-R02]** Gestor de recursos

El servidor no contempla el caso en que un mismo cliente se le asignen
varios recursos.
  
Un cliente tiene que tener la opción de solicitar, y obtener si es
posible, más de un recurso. De la misma forma tiene que poder liberar
cualquiera de los recursos asigandos.


## **[F-R03]** Gestor de recursos

El repositorio debe incluir la solución a cada una de las tres
iteraciones.


## **[F-R04]** Gestor de recursos

En la versión distribuida, el servidor no monitoriza los nodos que
contienen los clientes a los que se les asignó algún recurso. Esto
significa que si se cae el nodo, nunca se liberarán los recursos de
dichos clientes.


## **[F-R05]** Gestor de recursos

Una función `start` no debe crear el proceso con `start_link` esto es
incoherente con el nombre de la función y los clientes de esta función
no esperan ese comportamiento.

Además al crear el proceso con `start_link` este queda _linkado_ al
proceso que llama a `start`, con lo cual puede que termine cuando
termine dicho proceso, en general ese no es el comportamiento deseado.


## **[F-B01]** Micro bank

En el test que comprueba que el supervisor lanza un nuevo proceso
servidor en caso de que falle el actual, es importante comprobar que
efectivamente el primer proceso no está vivo y el proceso nuevo es
distinto al anterior.


## **[F-B02]** Micro bank

Los test tienen que ser independientes. Por tanto cada tests debe
dejar todo en el estado en que estaba, i.e. "limpiar" al acabar. En
este caso si el `setup` arranca el servidor, el `on_exit` tiene que
pararlo.


## **[F-B03]** Mirco bank

Os habéis cargado el `.gitignore` que crea `mix` y el repositorio está
polucionado con los resultados de la compilación: `_build/`.


## **[F-F01]** Servidores federados

Los clientes establecen el servidor, i.e. nodo, al que quieren enviar
la petición, no el pid ni el nombre de un proceso.


## **[F-F02]** Servidores federados

Si el actor que realiza la petición no pertenece al servidor, se
rechaza la petición.

Si el actor "destino" está registrado en otro servidor, hay que
redirigir la petición al dicho servidor. El actor "destino" es el
actor que recibe el mensaje o el actor cuyo perfil se desea consultar.


## **[F-F03]** Servidores federado

Tomemos como ejemplo la siguiente función que puede usar un cliente
del sistema:

  `def get_profile(requestor, actor) do`

Donde `requestor` es el actor "cliente" que realiza la petición y
`actor` es el actor cuyo perfil quiere consultar.

Recordemos las especificaciones del enunciado:

    Un cliente sólo puede hacer peticiones al servidor en que está registrado.
    Cada servidor se corresponde con un nodo elixir. El nombre del nodo y el
	del servidor son el mismo.
    Con estas restricciones, cada nodo sólo puede contener un servidor.

Por tanto, si `name_r@server_r <- requestor`:

    La petición se debe enviar al servidor que está en el nodo `server_r`.
    No confundir los servidores del sistema con los procesos gen_server de exlixir.
    Dentro del nodo hay que identificar el proceso que recibirá el mensaje
	del cliente. Por ejemplo, una implementación sencilla sería registrar
	el proceso con el mismo nombre que el nodo.

Una vez la petición ha llegado al proceso adecuado en el servidor:

    Los servidores no pueden confiar en los clientes y por tanto deben
	comprobar que requestor, efectivamente, es un actor registrado en el servidor.
    Si actor no está registrado en el servidor, la petición se delega en
	el servidor correspondiente.
