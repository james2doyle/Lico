<!--
Title: Welcome
Description: This is a long line that has some big words in it. Also some punctuation!
Special: <p>how about some HTML?</p>
Template: index
-->
<!-- here is a comment right at the top to try and fuck you up! -->

## Welcome to Lico

> This page was ripped from the PicoCMS index.md file!!

Congratulations, you have successfully installed [Lico](https://github.com/james2doyle/Lico). Lico is a stupidly simple, blazing fast, flat file CMS. This project is a conversion of [PicoCMS](http://picocms.org/).

### Creating Content

Lico is a flat file CMS, this means there is no administration backend and database to deal with. You simply create `.md` files in the "content"
folder and that becomes a page. For example, this file is called `index.md` and is shown as the main landing page.

If you create a folder within the content folder (e.g. `content/sub`) and put an `index.md` inside it, you can access that folder at the URL
`http://yousite.com/sub`. If you want another page within the sub folder, simply create a text file with the corresponding name (e.g. `content/sub/page.md`)
and you will be able to access it from the URL `http://yousite.com/sub/page`. Below we've shown some examples of content locations and their corresponing URL's:

<table>
  <thead>
    <tr><th>Physical Location</th><th>URL</th></tr>
  </thead>
  <tbody>
    <tr><td>content/index.md</td><td>/</td></tr>
    <tr><td>content/sub.md</td><td>/sub</td></tr>
    <tr><td>content/sub/index.md</td><td>/sub (same as above)</td></tr>
    <tr><td>content/sub/page.md</td><td>/sub/page</td></tr>
    <tr><td>content/a/very/long/url.md</td><td>/a/very/long/url</td></tr>
  </tbody>
</table>

If a file cannot be found, the file `content/404.md` will be shown.

### Text File Markup

Text files are marked up using [Markdown](http://daringfireball.net/projects/markdown/syntax). They can also contain regular HTML.

At the top of text files you can place a block comment and specify certain attributes of the page. For example:

```html
<!--
Title: Welcome
Description: This description will go in the meta description tag
Author: Joe Bloggs
Date: 2013/01/01
Robots: noindex,nofollow
-->
```

These values will be contained in the `#{= current_page }#` variable in themes (see below).

### Themes

You can create themes for your Lico installation in the "themes" folder. Check out the default theme for an example of a theme. Lico uses
[sltluv](http://twig.sensiolabs.org/documentation) for it's templating engine. You can select your theme by setting the `theme` variable in config.json to your theme folder.

You can use a `Template: ` key in your meta header to select an HTML file in your theme to load for that markdown file. By default, this key will be `index` when missing or undefined.

All themes must include an `index.html` file to define the HTML structure of the theme. Below are the Twig variables that are available to use in your theme:

* `#{= config }#` - Conatins the values you set in config.json (e.g. `#{= config.teme }#` = "default")
* `#{= theme_dir }#` - The path to the Lico active theme directory
* `#{= site_title }#` - Shortcut to the site title (defined in config.json)
* `#{= current_page }#` - Contains the current pages values
* `#{= content }#` - The content of the current page (after it has been processed through Markdown)
* `#{= pages }#` - A collection of all the pages in your content folder

Pages can be used like:

```html
<ul>
  #{ local i = 1
  while(pages[i]) do }#
  <li><a href="#{= pages[i].url }#">#{= pages[i].title }#</a></li>
  #{ i = i + 1
  end }#
</ul>
```

### Plugins

Not ready yet! But you can create extensions for the slt2 template engine.

### Config

You can override the default Lico settings (and add your own custom settings) by editing config.json in the root Lico directory. The config.json file lists all of the settings and their defaults. To override a setting, simply uncomment it in config.json and set your custom value.

### Documentation

For more help have a look at the Lico documentation at [https://github.com/james2doyle/Lico](https://github.com/james2doyle/Lico)