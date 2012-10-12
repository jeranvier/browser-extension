mem0r1es
=======

To install and run the Chrome extension:
* clone the repository on a local directory
* run `coffee --compile --output src/js/ src.coffee/` (requires the CoffeeScript compiler)
* "Load unpacked extension..." from [chrome://chrome/extensions/](chrome://chrome/extensions/) 
(requires enabling "Developer mode")

To execute the tests:
* run `coffee --compile --output tests/specs/ tests.coffee/`
* open `tests/run_*.html` in the browser