module Rdm
  module Utils
    class StringUtils
      class << self
        def camelize(string, uppercase_first_letter = true)
          if uppercase_first_letter
            string = string.sub(/^[a-z\d]*/) { $&.capitalize }
          else
            string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { $&.downcase }
          end
          string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
        end
      end
    end
  end
end