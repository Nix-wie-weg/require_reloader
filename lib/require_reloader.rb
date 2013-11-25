require "require_reloader/version"
require "require_reloader/railtie"
require "require_reloader/helper"

module RequireReloader
  class << self

    # Reload all local gems (that is, ones which have a :path attribute)
    # automatically on each request.
    #
    # To use it, add 'RequireReloader.watch_local_gems!' to
    # your config/environments/development.rb.
    #
    def watch_local_gems!
      local_gems.each do |gem|
        # never reload itself for now, causing error raised in integration test
        next if gem[:name] == 'require_reloader'

        watch gem[:name], :path => gem[:path]
      end
    end

    def first_run?
      !!@first_run
    end

    def first_run= value
      @first_run = value
    end

    # Propose to deprecate :watch_all! and reserve it for future usage.
    alias_method :watch_all!, :watch_local_gems!

    # Reload a specific gem or a gem-like .rb file
    # automatically on each request.
    #
    # In Rails 3.2+, reload happens only when a watchable file is modified.
    #
    # To use it, add 'RequireReloader.watch :my_gem' to
    # your config/environments/development.rb.
    #
    def watch(gem_name, opts={})
      gem            = gem_name.to_s
      watchable_dir  = expanded_gem_path(gem, opts[:path])
      watchable_exts = opts[:exts] ? Array(opts[:exts]) : [:rb]
      helper         = Helper.new

      app = Object.const_get(Rails.application.class.parent_name)
      app::Application.configure do

        if watchable_dir && config.respond_to?(:watchable_dirs)
          config.watchable_dirs[watchable_dir] = watchable_exts
        end

        # based on Tim Cardenas's solution:
        # http://timcardenas.com/automatically-reload-gems-in-rails-327-on-eve
        ActionDispatch::Callbacks.to_prepare do
          # Do nothing on the first run. Reload on subsequent requests.
          unless RequireReloader.first_run?
            helper.remove_module_if_defined(gem)
            $".delete_if {|s| s.include?(gem)}
            require gem
            opts[:callback].call(gem) if opts[:callback]
          end
        end
        ActionDispatch::Callbacks.to_cleanup do
          # First run is over when cleanup starts.
          RequireReloader.first_run = false
        end
      end
    end

    private

    def expanded_gem_path(gem, preferred_path)
      return File.expand_path(preferred_path) if preferred_path
      local_gem = local_gems.find {|g| g[:name] == gem}
      local_gem ? File.expand_path(local_gem[:path]) : false
    end

    # returns only local gems, local git repo
    def local_gems
      Bundler.definition.specs.
        select{|s| s.source.is_a?(Bundler::Source::Path) }.
        delete_if{|s| s.source.is_a?(Bundler::Source::Git) && !s.source.send(:local?) }.
        map{|s| {:name => s.name, :path => s.source.path.to_s} }
    end
  end

  self.first_run = true
end
