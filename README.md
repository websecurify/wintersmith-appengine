# wintersmith-appengine

Plugin for [wintersmith](https://github.com/jnordberg/wintersmith) which converts the build directory into a Google Appengine compatible app. Works with wintersmith 2.

### Install

Just add it to your wintersmith plugins as you would usually do.

### Configuration

Your config.json file should look more or less like this:

	{
		"locals": {
		},
		
		"plugins": [
			"wintersmith-appengine"
		],
		
		"appengine": {
			"application": "NAME",
			"version": VERSION
		}
	}

Additionally you can map Appengine URLs to site urls via mappings. Here is an example:

	{
		"locals": {
		},
	
		"plugins": [
			"wintersmith-appengine"
		],
	
		"appengine": {
			"application": "NAME",
			"version": VERSION,
		
			"mappings": {
				"path/to/some/url": "local/path/to/file"
			}
		}
	}
