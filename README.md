Lico
====

Pico ([github](https://github.com/picocms/Pico) or [homepage](http://picocms.org/)) re-created using [Luvit](https://github.com/luvit/luvit).

### What is Lico?

Pico says, *"Pico is a stupidly simple, blazing fast, flat file CMS"*. Lico aims for the same thing. There is a very close parity with Pico even though this is very early.

I used the static server from the Luvit examples as a base and went from there.

### How to run?

Just do a `luvit server.lua` and you should be up and running. Take a look at the `config.json` to make sure that all the settings are correct for your system.

### How to create content?

You can understand the basics by looking at the included content directory and just running the `server.lua` file and hitting the index page.

If you need more information you can see the [Pico docs](http://picocms.org/docs.html) and understand what is happening and how it works.

### What features are implemented?

* Markdown Parsing using [luvit-markdown](https://github.com/mneudert/luvit-markdown) -- *looking to switch to [Hoedown](https://github.com/torch/sundown-ffi/tree/hoedown)*
* HTML Templating (using my own modified version of [SLT2](https://github.com/james2doyle/sltluv)
* Flexible Meta schema (Uses HTML comments instead of PHP style)

### Whats missing?

Plugins. Although with the native of the [Event Emitter](https://github.com/luvit/luvit/blob/master/examples/event-emitters.lua) inside Luvit, this should be rather easy to re-create.

You can use SLTLuv to add new functions and features to your templates. You can see the `modules/slt-extensions.lua` on how to add extensions to the templates. I also added in some examples in the `default/themes/index.html`, if you want to see how they work.

Check out the [slt2 examples](https://github.com/henix/slt2#example) to see how to write proper templates.

The markdown engine is rather simple. There is no fenced code blocks, and sometimes it will wrap uncommon HTML tags with `<p>` tags (I tried using a `figure` element and it was wrapped in p tags). I want switch to [Hoedown](https://github.com/torch/sundown-ffi/tree/hoedown) soon.

### Performance

Well, this is very interesting. Running the default setup for Pico and Lico, reveals Lico is twice as fast in at the browser level.

Using the Chrome Devtools Network Panel, I measured the index page of each system. I consistently got around 120ms for each request. For Pico, the results were varied quite a bit. They ranged from 200ms to as high as 500ms, but never going under 200ms.

There are a lot of factors here, but the default Pico has 3 pages and my Lico testing suite (same one as this repo) had 6 pages.

I did some other testing against my other project, [PhileCMS](https://github.com/PhileCMS/Phile#performance-with-20-pages). You can see that Pico doesn't handle large amounts of pages very well.

### There are issues!

Yeah I bet. I am not a Lua developer. I made this over a week-long period trying to learn Lua. If you notice some funky stuff or clean n00b issues, please create issues or pull requests.