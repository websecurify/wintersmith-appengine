fs = require 'fs'
path = require 'path'

module.exports = (env, callback) ->
	env.readJSON 'config.json', (error, config) ->
		if error
			return callback(error)

		if not config.appengine?
			return callback()

		yaml = """
		application: #{config.appengine.application or 'application'}
		version: #{config.appengine.version or 1}
		runtime: python27
		api_version: 1
		threadsafe: yes

		default_expiration: "1d"

		handlers:
		- url: /(.*\\.(appcache|manifest))
		  mime_type: text/cache-manifest
		  static_files: \\1
		  upload: (.*\\.(appcache|manifest))
		  expiration: "0m"

		- url: /(.*\\.atom)
		  mime_type: application/atom+xml
		  static_files: \\1
		  upload: (.*\\.atom)
		  expiration: "1h"

		- url: /(.*\\.crx)
		  mime_type: application/x-chrome-extension
		  static_files: \\1
		  upload: (.*\\.crx)

		- url: /(.*\\.css)
		  mime_type: text/css
		  static_files: \\1
		  upload: (.*\\.css)

		- url: /(.*\\.eot)
		  mime_type: application/vnd.ms-fontobject
		  static_files: \\1
		  upload: (.*\\.eot)

		- url: /(.*\\.htc)
		  mime_type: text/x-component
		  static_files: \\1
		  upload: (.*\\.htc)

		- url: /(.*\\.html)
		  mime_type: text/html
		  static_files: \\1
		  upload: (.*\\.html)
		  expiration: "1h"

		- url: /(.*\\.ico)
		  mime_type: image/x-icon
		  static_files: \\1
		  upload: (.*\\.ico)
		  expiration: "7d"

		- url: /(.*\\.js)
		  mime_type: text/javascript
		  static_files: \\1
		  upload: (.*\\.js)

		- url: /(.*\\.json)
		  mime_type: application/json
		  static_files: \\1
		  upload: (.*\\.json)
		  expiration: "1h"

		- url: /(.*\\.m4v)
		  mime_type: video/m4v
		  static_files: \\1
		  upload: (.*\\.m4v)

		- url: /(.*\\.mp4)
		  mime_type: video/mp4
		  static_files: \\1
		  upload: (.*\\.mp4)

		- url: /(.*\\.(ogg|oga))
		  mime_type: audio/ogg
		  static_files: \\1
		  upload: (.*\\.(ogg|oga))

		- url: /(.*\\.ogv)
		  mime_type: video/ogg
		  static_files: \\1
		  upload: (.*\\.ogv)

		- url: /(.*\\.otf)
		  mime_type: font/opentype
		  static_files: \\1
		  upload: (.*\\.otf)

		- url: /(.*\\.rss)
		  mime_type: application/rss+xml
		  static_files: \\1
		  upload: (.*\\.rss)
		  expiration: "1h"

		- url: /(.*\\.safariextz)
		  mime_type: application/octet-stream
		  static_files: \\1
		  upload: (.*\\.safariextz)

		- url: /(.*\\.(svg|svgz))
		  mime_type: images/svg+xml
		  static_files: \\1
		  upload: (.*\\.(svg|svgz))

		- url: /(.*\\.swf)
		  mime_type: application/x-shockwave-flash
		  static_files: \\1
		  upload: (.*\\.swf)

		- url: /(.*\\.ttf)
		  mime_type: font/truetype
		  static_files: \\1
		  upload: (.*\\.ttf)

		- url: /(.*\\.txt)
		  mime_type: text/plain
		  static_files: \\1
		  upload: (.*\\.txt)

		- url: /(.*\\.unity3d)
		  mime_type: application/vnd.unity
		  static_files: \\1
		  upload: (.*\\.unity3d)

		- url: /(.*\\.webm)
		  mime_type: video/webm
		  static_files: \\1
		  upload: (.*\\.webm)

		- url: /(.*\\.webp)
		  mime_type: image/webp
		  static_files: \\1
		  upload: (.*\\.webp)

		- url: /(.*\\.woff)
		  mime_type: application/x-font-woff
		  static_files: \\1
		  upload: (.*\\.woff)

		- url: /(.*\\.xml)
		  mime_type: application/xml
		  static_files: \\1
		  upload: (.*\\.xml)
		  expiration: "1h"

		- url: /(.*\\.xpi)
		  mime_type: application/x-xpinstall
		  static_files: \\1
		  upload: (.*\\.xpi)

		# image files
		- url: /(.*\\.(bmp|gif|ico|jpeg|jpg|png))
		  static_files: \\1
		  upload: (.*\\.(bmp|gif|ico|jpeg|jpg|png))

		# audio files
		- url: /(.*\\.(mid|midi|mp3|wav))
		  static_files: \\1
		  upload: (.*\\.(mid|midi|mp3|wav))  

		# windows files
		- url: /(.*\\.(doc|exe|ppt|rtf|xls))
		  static_files: \\1
		  upload: (.*\\.(doc|exe|ppt|rtf|xls))

		# compressed files
		- url: /(.*\\.(bz2|gz|rar|tar|tgz|zip))
		  static_files: \\1
		  upload: (.*\\.(bz2|gz|rar|tar|tgz|zip))

		# mappings

		# index files
		- url: /(.+)/
		  static_files: \\1/index.html
		  upload: (.+)/index.html
		  expiration: "15m"

		- url: /(.+)
		  static_files: \\1/index.html
		  upload: (.+)/index.html
		  expiration: "15m"

		# site root
		- url: /
		  static_files: index.html
		  upload: index.html
		  expiration: "15m"

		# others
		- url: /.*
		  script: app.application
		"""

		if config.appengine.mappings?
			mappings = []

			for key, value of config.appengine.mappings
				mappings.push "- url: #{key}"
				mappings.push "  static_files: #{value}"
				mappings.push "  upload: #{value}"
				mappings.push ""

			if mappings
				yaml = yaml.replace '# mappings\n', '#mappings\n' + mappings.join('\n')
			else
				yaml = yaml.replace '# mappings\n', ''

		py = """
		import webapp2

		application = webapp2.WSGIApplication([], debug=False)
		"""

		fs.writeFile path.join('build', 'app.yaml'), yaml, (error) ->
			if error
				callback(error)
			else
				fs.writeFile path.join('build', 'app.py'), py, callback