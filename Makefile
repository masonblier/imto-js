REPORTER = dot

browser: browser-make

browser-make:
	browserify -o public/redl.js lib/browser.js

test: test-unit

test-unit:
	@NODE_ENV=test ./node_modules/.bin/mocha \
		--reporter $(REPORTER)
