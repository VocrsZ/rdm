class Rdm::Settings
  attr_reader :settings

  SETTING_KEYS = [
    :role, :package_subdir_name, :config_path,
    :silence_missing_package_file, :silence_missing_package, :compile_path,
    :compile_ignore_files, :compile_add_files
  ].freeze

  SETTING_VARIABLES = [:role].freeze

  # Default settings
  def initialize
    silence_missing_package       false
    silence_missing_package_file  false
    package_subdir_name           'package'
    compile_ignore_files          %w(.gitignore .byebug_history .irbrc .rspec *_spec.rb *.log)
    compile_add_files             %w(Gemfile Gemfile.lock)
    compile_path                  '/tmp/rdm/:package_name'
    config_path                   'config/:role.yml'
  end

  SETTING_KEYS.each do |key|
    define_method(key) do |value = nil, &block|
      fetch_setting key, value, &block
    end
  end

  def fetch_setting(key, value = nil, &block)
    if value.nil? && !block_given?
      read_setting(key)
    else
      write_value = value.nil? ? block : value
      write_setting(key, write_value)
    end
  end

  def read_setting(key, vars: {})
    value = @settings[key.to_s]
    if value.is_a?(Proc)
      value.call
    elsif value.is_a?(String)
      replace_variables(value, except: key, additional_vars: vars)
    else
      value
    end
  end

  private

  def write_setting(key, value)
    @settings ||= {}
    @settings[key.to_s] = value
  end

  def replace_variables(value, except: nil, additional_vars: {})
    variables_keys = SETTING_VARIABLES - [except.to_sym]
    new_value = value
    additional_vars.each do |key, variable|
      if new_value.match(":#{key}")
        new_value = new_value.gsub(":#{key}", variable)
      end
    end
    variables_keys.each do |key|
      if new_value.match(":#{key}")
        new_value = new_value.gsub(":#{key}", read_setting(key))
      end
    end
    new_value
  end
end
