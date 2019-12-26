Deployment
==========

The following sections describe a variety of deployment strategies for
Engine.IO servers.

aiohttp
-------

`aiohttp <http://aiohttp.readthedocs.io/>`_ provides a framework with support
for HTTP and WebSocket, based on asyncio. Support for this framework is limited
to Python 3.5 and newer.

Instances of class ``engineio.AsyncServer`` will automatically use aiohttp
for asynchronous operations if the library is installed. To request its use
explicitly, the ``async_mode`` option can be given in the constructor::

    eio = engineio.AsyncServer(async_mode='aiohttp')

A server configured for aiohttp must be attached to an existing application::

    app = web.Application()
    eio.attach(app)

The aiohttp application can define regular routes that will coexist with the
Engine.IO server. A typical pattern is to add routes that serve a client
application and any associated static files.

The aiohttp application is then executed in the usual manner::

    if __name__ == '__main__':
        web.run_app(app)

Tornado
-------

`Tornado <http://www.tornadoweb.org//>`_ is a web framework with support
for HTTP and WebSocket. Support for this framework requires Python 3.5 and
newer. Only Tornado version 5 and newer are supported, thanks to its tight
integration with asyncio.

Instances of class ``engineio.AsyncServer`` will automatically use tornado
for asynchronous operations if the library is installed. To request its use
explicitly, the ``async_mode`` option can be given in the constructor::

    eio = engineio.AsyncServer(async_mode='tornado')

A server configured for tornado must include a request handler for
Engine.IO::

    app = tornado.web.Application(
        [
            (r"/engine.io/", engineio.get_tornado_handler(eio)),
        ],
        # ... other application options
    )

The tornado application can define other routes that will coexist with the
Engine.IO server. A typical pattern is to add routes that serve a client
application and any associated static files.

The tornado application is then executed in the usual manner::

    app.listen(port)
    tornado.ioloop.IOLoop.current().start()

Sanic
-----

`Sanic <http://sanic.readthedocs.io/>`_ is a very efficient asynchronous web
server for Python 3.5 and newer.

Instances of class ``engineio.AsyncServer`` will automatically use Sanic for
asynchronous operations if the framework is installed. To request its use
explicitly, the ``async_mode`` option can be given in the constructor::

    eio = engineio.AsyncServer(async_mode='sanic')

A server configured for Sanic must be attached to an existing application::

    app = Sanic()
    eio.attach(app)

The Sanic application can define regular routes that will coexist with the
Engine.IO server. A typical pattern is to add routes that serve a client
application and any associated static files to this application.

The Sanic application is then executed in the usual manner::

    if __name__ == '__main__':
        app.run()

Uvicorn, Daphne, and other ASGI servers
---------------------------------------

The ``engineio.ASGIApp`` class is an ASGI compatible application that can
forward Engine.IO traffic to an ``engineio.AsyncServer`` instance::

   eio = engineio.AsyncServer(async_mode='asgi')
   app = engineio.ASGIApp(eio)

The application can then be deployed with any ASGI compatible web server.

Eventlet
--------

`Eventlet <http://eventlet.net/>`_ is a high performance concurrent networking
library for Python 2 and 3 that uses coroutines, enabling code to be written in
the same style used with the blocking standard library functions. An Engine.IO
server deployed with eventlet has access to the long-polling and WebSocket
transports.

Instances of class ``engineio.Server`` will automatically use eventlet for
asynchronous operations if the library is installed. To request its use
explicitly, the ``async_mode`` option can be given in the constructor::

    eio = engineio.Server(async_mode='eventlet')

A server configured for eventlet is deployed as a regular WSGI application,
using the provided ``engineio.Middleware``::

    app = engineio.Middleware(eio)
    import eventlet
    eventlet.wsgi.server(eventlet.listen(('', 8000)), app)

Using Gunicorn with Eventlet
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An alternative to running the eventlet WSGI server as above is to use
`gunicorn <gunicorn.org>`_, a fully featured pure Python web server. The
command to launch the application under gunicorn is shown below::

    $ gunicorn -k eventlet -w 1 module:app

Due to limitations in its load balancing algorithm, gunicorn can only be used
with one worker process, so the ``-w 1`` option is required. Note that a
single eventlet worker can handle a large number of concurrent clients.

Another limitation when using gunicorn is that the WebSocket transport is not
available, because this transport it requires extensions to the WSGI standard.

Note: Eventlet provides a ``monkey_patch()`` function that replaces all the
blocking functions in the standard library with equivalent asynchronous
versions. While python-engineio does not require monkey patching, other
libraries such as database drivers are likely to require it.

Gevent
------

`Gevent <http://gevent.org>`_ is another asynchronous framework based on
coroutines, very similar to eventlet. An Engine.IO server deployed with
gevent has access to the long-polling transport. If project
`gevent-websocket <https://bitbucket.org/Jeffrey/gevent-websocket/>`_ is
installed, the WebSocket transport is also available. Note that when using the
uWSGI server, the native WebSocket implementation of uWSGI can be used instead
of gevent-websocket (see next section for details on this).

Instances of class ``engineio.Server`` will automatically use gevent for
asynchronous operations if the library is installed and eventlet is not
installed. To request gevent to be selected explicitly, the ``async_mode``
option can be given in the constructor::

    # gevent alone or with gevent-websocket
    eio = engineio.Server(async_mode='gevent')

A server configured for gevent is deployed as a regular WSGI application,
using the provided ``engineio.Middleware``::

    from gevent import pywsgi
    app = engineio.Middleware(eio)
    pywsgi.WSGIServer(('', 8000), app).serve_forever()

If the WebSocket transport is installed, then the server must be started as
follows::

    from gevent import pywsgi
    from geventwebsocket.handler import WebSocketHandler
    app = engineio.Middleware(eio)
    pywsgi.WSGIServer(('', 8000), app,
                      handler_class=WebSocketHandler).serve_forever()

Using Gunicorn with Gevent
~~~~~~~~~~~~~~~~~~~~~~~~~~

An alternative to running the gevent WSGI server as above is to use
`gunicorn <gunicorn.org>`_, a fully featured pure Python web server. The
command to launch the application under gunicorn is shown below::

    $ gunicorn -k gevent -w 1 module:app

Or to include WebSocket::

    $ gunicorn -k geventwebsocket.gunicorn.workers.GeventWebSocketWorker -w 1 module: app

Same as with eventlet, due to limitations in its load balancing algorithm,
gunicorn can only be used with one worker process, so the ``-w 1`` option is
required. Note that a single gevent worker can handle a large number of
concurrent clients.

Note: Gevent provides a ``monkey_patch()`` function that replaces all the
blocking functions in the standard library with equivalent asynchronous
versions. While python-engineio does not require monkey patching, other
libraries such as database drivers are likely to require it.

uWSGI
-----

When using the uWSGI server in combination with gevent, the Engine.IO server
can take advantage of uWSGI's native WebSocket support.

Instances of class ``engineio.Server`` will automatically use this option for
asynchronous operations if both gevent and uWSGI are installed and eventlet is
not installed. To request this asynchoronous mode explicitly, the
``async_mode`` option can be given in the constructor::

    # gevent with uWSGI
    eio = engineio.Server(async_mode='gevent_uwsgi')

A complete explanation of the configuration and usage of the uWSGI server is
beyond the scope of this documentation. The uWSGI server is a fairly complex
package that provides a large and comprehensive set of options. It must be
compiled with WebSocket and SSL support for the WebSocket transport to be
available. As way of an introduction, the following command starts a uWSGI
server for the ``latency.py`` example on port 5000::

    $ uwsgi --http :5000 --gevent 1000 --http-websockets --master --wsgi-file latency.py --callable app

Standard Threads
----------------

While not comparable to eventlet and gevent in terms of performance,
the Engine.IO server can also be configured to work with multi-threaded web
servers that use standard Python threads. This is an ideal setup to use with
development servers such as `Werkzeug <http://werkzeug.pocoo.org>`_. Only the
long-polling transport is currently available when using standard threads.

Instances of class ``engineio.Server`` will automatically use the threading
mode if neither eventlet nor gevent are not installed. To request the
threading mode explicitly, the ``async_mode`` option can be given in the
constructor::

    eio = engineio.Server(async_mode='threading')

A server configured for threading is deployed as a regular web application,
using any WSGI complaint multi-threaded server. The example below deploys an
Engine.IO application combined with a Flask web application, using Flask's
development web server based on Werkzeug::

    eio = engineio.Server(async_mode='threading')
    app = Flask(__name__)
    app.wsgi_app = engineio.Middleware(eio, app.wsgi_app)

    # ... Engine.IO and Flask handler functions ...

    if __name__ == '__main__':
        app.run(threaded=True)

When using the threading mode, it is important to ensure that the WSGI server
can handle multiple concurrent requests using threads, since a client can have
up to two outstanding requests at any given time. The Werkzeug server is
single-threaded by default, so the ``threaded=True`` option is required.

Note that servers that use worker processes instead of threads, such as
gunicorn, do not support an Engine.IO server configured in threading mode.

Scalability Notes
-----------------

Engine.IO is a stateful protocol, which makes horizontal scaling more
difficult. To deploy a cluster of Engine.IO processes hosted on one or
multiple servers the following conditions must be met:

- Each Engine.IO server process must be able to handle multiple requests
  concurrently. This is required because long-polling clients send two
  requests in parallel. Worker processes that can only handle one request at a
  time are not supported.
- The load balancer must be configured to always forward requests from a client
  to the same process. Load balancers call this *sticky sessions*, or
  *session affinity*.
