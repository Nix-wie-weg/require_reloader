module RequireReloader
  # Methods copied from latest ActiveSupport::Inflector to support
  # older Rails versions (e.g. 3.0) without these methods.
  module ActionPackInfectorMethods
    def deconstantize(path)
      path.to_s[0...(path.rindex('::') || 0)] # implementation based on the one in facets' Module#spacename
    end

    def constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end

    def const_regexp(camel_cased_word) #:nodoc:
      parts = camel_cased_word.split("::")
      last  = parts.pop

      parts.reverse.inject(last) do |acc, part|
        part.empty? ? acc : "#{part}(::#{acc})?"
      end
    end

    def demodulize(path)
      path = path.to_s
      if i = path.rindex('::')
        path[(i+2)..-1]
      else
        path
      end
    end

    def safe_constantize(camel_cased_word)
      begin
        constantize(camel_cased_word)
      rescue NameError => e
        raise unless e.message =~ /(uninitialized constant|wrong constant name) #{const_regexp(camel_cased_word)}$/ ||
        e.name.to_s == camel_cased_word.to_s
      rescue ArgumentError => e
        raise unless e.message =~ /not missing constant #{const_regexp(camel_cased_word)}\!$/
      end
    end
  end

  class Helper
    include ActionPackInfectorMethods

    def remove_gem_module_if_defined(gem_name)
      mod_name = full_qualified_name(gem_name)
      remove_module_if_defined(mod_name)
    end

    def remove_module_if_defined(mod_name)
      remove_module(mod_name) if module_defined?(mod_name)
    end

    def module_defined?(full_name)
      !!safe_constantize(full_name)
    end

    def remove_module(full_name)
      module_namespace = deconstantize(full_name)
      module_name = demodulize(full_name)
      parent_module = module_namespace == "" ? Object : constantize(module_namespace)
      parent_module.send(:remove_const, module_name)
    end

    def full_qualified_name(gem_name)
      return nil unless gem_name
      gem_name.split("-").map{|token| camelcase(token)}.join("::")
    end

    def camelcase(str)
      str.split("_").map{|token| token.capitalize }.join("")
    end

    def to_prepare(&block)
      if Rails::VERSION::MAJOR == 5
        ActiveSupport::Reloader.to_prepare(&block)
      else
        ActionDispatch::Callbacks.to_prepare(&block)
      end
    end
  end

end
