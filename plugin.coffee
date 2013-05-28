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
		
		env_variables:
		  NOT_FOUND_PAGE: #{config.appengine.notFoundPage or '""'}
		  NOT_FOUND_PAGE_IS_REDIRECT: #{config.appengine.notFoundPageIsRedirect or 'false'}
		  
		default_expiration: "1d"
		
		handlers:
		# mappings
		
		# all
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
				
			if mappings.length
				yaml = yaml.replace '# mappings\n', '#mappings\n' + mappings.join('\n')
			else
				yaml = yaml.replace '# mappings\n\n', ''
		else
			yaml = yaml.replace '# mappings\n\n', ''
			
		py = """
		import mimetypes
		import webapp2
		import os
		
		mimetypes.add_type('application/font-woff', '.woff')
		
		class RequestHandler(webapp2.RequestHandler):
			root = os.path.dirname(__file__)
			
			def get(self):
				path_parts = [self.root] + self.request.path.split('/')
				final_path = os.path.join(*path_parts)
				
				if not os.path.exists(final_path):
					if 'NOT_FOUND_PAGE' in os.environ and os.environ['NOT_FOUND_PAGE']:
						if 'NOT_FOUND_PAGE_IS_REDIRECT' in os.environ and os.environ['NOT_FOUND_PAGE_IS_REDIRECT']:
							self.redirect(os.environ['NOT_FOUND_PAGE'])
							
							return
							
						path_parts = [self.root] + os.environ['NOT_FOUND_PAGE'].split('/')
						final_path = os.path.join(*path_parts)
						
						if not os.path.exists(final_path):
							return
							
						self.response.set_status(404)
						
					else:
						return
						
				if os.path.isdir(final_path):
					path_parts = path_parts + ['index.html']
					final_path = os.path.join(*path_parts)
					
				self.response.headers['Content-Type'] = mimetypes.guess_type(os.path.basename(final_path))[0] or 'application/octet-stream'
				
				self.response.cache_control.no_cache = None
				self.response.cache_control.public = True
				self.response.cache_control.max_age = 86400
				
				file = open(final_path)
				
				self.response.write(file.read())
				
				file.close()
				
		application = webapp2.WSGIApplication([
			('/.*', RequestHandler)
		], debug=False)
		"""
		
		fs.writeFile path.join('build', 'app.yaml'), yaml, (error) ->
			if error
				callback(error)
			else
				fs.writeFile path.join('build', 'app.py'), py, callback