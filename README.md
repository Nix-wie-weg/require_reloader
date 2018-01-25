# RequireReloader

[![Gem Version](https://badge.fury.io/rb/require_reloader.png)](http://badge.fury.io/rb/require_reloader)

Auto-reload `require` files or local gems without restarting server
during Rails development.

Currently, it supports Rails 3+ and above, including 3.1 and 3.2.

It uses `ActionDispatch::Callbacks.to_prepare` to reload the
`require` files before each request. In Rails 3.2, it uses
`watchable_dirs` to reload only when you modify a file. More details in [this blog post](http://teohm.github.com/blog/2013/01/10/reload-required-files-in-rails/).

## Usage

Given a `Gemfile`

    # Gemfile
    gem 'my_gem',  :path => '~/work/my_gem'
    gem 'my_gem2', :path => '~/fun/my_gem2', :module_name => 'MYGEM2'

To reload all **local gems** (the ones with `:path` attribute,
or using [local git repo](http://gembundler.com/v1.2/git.html#local)):

    # config/environments/development.rb
    YourApp::Application.configure do
      ...
      RequireReloader.watch_local_gems!
    end

To reload a specific local gem:

    RequireReloader.watch :my_gem

You can also **reload a `.rb` file in `lib`** or any directory:

    RequireReloader.watch :half_baked_gem  # in lib dir
    RequireReloader.watch :foo, :path => 'app/models'

The `:path` option is *optional*. In **Rails 3.2**, `:path` value is added into `watchable_dirs`. Rails 3.1 and 3.0 ignore this value.

The `:module_name` option is *optional*. By default, it is assumed that the top-level module is a CamelCase version of the gem name.
If this is not the case, you can pass this option, a String. This value will also be picked up if included in the metadata of the gemspec,
as in `spec.metadata = {'module_name' => 'MYMOD'}`.

RequireReloader adds `lib` into `watchable_dirs`. So, specify `:path`
only if it is not specified in `Gemfile` and the file is located in other directory.

    RequireReloader.watch :foo, :callback => lambda { |gem| puts "#{gem} got reloaded" }

You can supply a Proc with the *optional* `:callback` option. This proc gets called everytime after your gem got reloaded.

## Installation

Add this line to your application's Gemfile:

    gem 'require_reloader'

And then execute:

    $ bundle


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Credits

This gem is forked from Colin Young's [gem_reloader](https://github.com/colinyoung/gem_reloader), based on [a solution by Timothy Cardenas](http://timcardenas.com/automatically-reload-gems-in-rails-327-on-eve), inspired by [a post from Leitch](http://ileitch.github.com/2012/03/24/rails-32-code-reloading-from-lib.html).

### Contributors
- @sven-winkler: trigger callback after gem reloaded (issue #2)
- @aceofspades: support gem metadata :module_name in Gemfile (issue #4)

## Changelog
- v0.2.1: Add Rails 5.1 support ([pull request](https://github.com/teohm/require_reloader/pull/7) from @kibenimatik)
- v0.2.0: Support module_name option/spec-metadata
- v0.1.6: RequireReloader::watch accepts :callback, runs it after gem reloaded ([pull request](https://github.com/teohm/require_reloader/pull/2) from @sven-winkler).
- v0.1.5: properly guess top-level module name based on gem name
pattern, only watch git repo if it's local.
- v0.1.4: remove 'vendor/gems' from watchable_dirs & autoload_paths, as local gem path is already specified in Gemfile.
- v0.1.3: Skip reload local gem if it's itself; added integration tests.
- v0.1.2: Minor rephrase on gem's description and summary.
- v0.1.1: Use Bundler to fetch local gems info, instead of parsing Gemfile by hand.
- v0.1.0: Forked colinyoung/gem_reloader, renamed & major rewrite to support Rails 3.2 and new features.
- v0.0.2: Added "vendor/gems" to the config.autoload_paths so the user doesn't have to.
