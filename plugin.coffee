fs = require 'fs'
path = require 'path'

# ---

module.exports = (env, callback) ->
	config = env.config
	
	# ---
	
	yaml = """
	application: #{config.appengine.application or 'application'}
	version: #{config.appengine.version or 1}
	runtime: python27
	api_version: 1
	threadsafe: yes
	
	default_expiration: "1d"
	
	handlers:
	- url: /.*
	  script: app.application
	"""
	
	# ---
	
	config_object = JSON.stringify(config).replace(/:null/g, ':None').replace(/:true/g, ':True').replace(/:false/g, ':False')
	
	# ---
	
	py = """
	import mimetypes
	import webapp2
	import os
	
	# ---
	
	mimetypes.add_type('image/svg+xml', '.svg')
	mimetypes.add_type('application/font-woff', '.woff')
	
	# ---
	
	true = True
	false = False
	config = #{config_object}
	
	# ---
	
	if 'appengine' not in config:
		config['appengine'] = {}
		
	# ---
	
	class RequestHandler(webapp2.RequestHandler):
		root = os.path.dirname(__file__)
		
		# ---
		
		def get(self):
			path_parts = [self.root] + self.request.path.split('/')
			final_path = os.path.join(*path_parts)
			
			# ---
			
			if not os.path.exists(final_path):
				if 'notFoundPage' in config['appengine'] and config['appengine']['notFoundPage']:
					if 'notFoundPageIsRedirect' in config['appengine'] and config['appengine']['notFoundPageIsRedirect']:
						self.redirect(config['appengine']['notFoundPage'])
						
						# ---
						
						return
						
					# ---
					
					path_parts = [self.root] + config['appengine']['notFoundPage'].split('/')
					final_path = os.path.join(*path_parts)
					
					# ---
					
					if not os.path.exists(final_path):
						return
						
					# ---
					
					self.response.set_status(404)
					
				else:
					return
					
			# ---
			
			if os.path.isdir(final_path):
				path_parts = path_parts + ['index.html']
				final_path = os.path.join(*path_parts)
				
			# ---
			
			self.response.headers['Content-Type'] = mimetypes.guess_type(os.path.basename(final_path))[0] or 'application/octet-stream'
			
			# ---
			
			self.response.cache_control.no_cache = None
			self.response.cache_control.public = True
			self.response.cache_control.max_age = 86400
			
			# ---
			
			file = open(final_path)
			
			self.response.write(file.read())
			
			file.close()
			
	# ---
	
	routes = []
	
	# ---
	
	if 'permanents' in config['appengine']:
	    for route, url in config['appengine']['permanents'].iteritems():
	        routes.append(webapp2.Route(route, webapp2.RedirectHandler, defaults={'_code': 301, '_uri': url}))
			
	# ---
	
	if 'redirects' in config['appengine']:
	    for route, url in config['appengine']['redirects'].iteritems():
	        routes.append(webapp2.Route(route, webapp2.RedirectHandler, defaults={'_code': 302, '_uri': url}))
    		
	# ---
	
	routes.append(('/.*', RequestHandler))
	
	# ---
	
	application = webapp2.WSGIApplication(routes, debug=False)
	"""
	
	# ---
	
	build_path = 'build'
	app_yaml_path = path.join build_path, 'app.yaml'
	
	# ---
	
	if fs.existsSync build_path
		fs.writeFile app_yaml_path, yaml, (err) ->
			return callback if err
			return fs.writeFile (path.join 'build', 'app.py'), py, callback
	else
		return callback null
		
# ---
