module Rdm
  module Handlers
    class DependenciesHandler
      ALREADY_MENTIONED_DEPS = '...'
      HYPHEN                 = "\xE2\x94\x80" * 2
      CORNER                 = "\xE2\x94\x80" + HYPHEN + " "
      MIDDLE_CORNER          = "\xE2\x94\x9C" + HYPHEN + " "
      
      class << self
        def show_names(package_name:, project_path:)
          new(package_name, project_path).show_names
        end

        def show_packages(package_name:, project_path:)
          new(package_name, project_path).show_packages
        end
        
        def draw(package_name:, project_path:)
          if package_name.to_s.empty?
            raise Rdm::Errors::InvalidParams, "Type package name, ex: rdm gen.deps repository" 
          end
        
          new(package_name, project_path).draw
        end
      end
      
      def initialize(package_name, project_path)
        @package_name = package_name
        @project_path = project_path

        check_params!(
          package_name: @package_name, 
          project_path: @project_path
        )
      end

      def show_names        
        recursive_find_dependencies([@package_name])
      end

      def show_packages
        names = show_names

        source.packages.values.select do |p| 
          names.include?(p.name)
        end
      end

      def draw(package_data = nil, uniq_packages = [], self_predicate = '', child_predicate = '')
        package_data    ||= { 
          name:   @package_name,
          groups: [Rdm::Package::DEFAULT_GROUP] 
        }

        raise Rdm::Errors::PackageHasNoDependencies, @package_name if source.packages[@package_name].local_dependencies.empty?

        node = [format_package_name(package_data[:name], package_data[:groups], self_predicate)]
        
        return node if package_data[:name] == ALREADY_MENTIONED_DEPS

        local_dependencies = source.packages[package_data[:name]].local_dependencies_with_groups

        if uniq_packages.include?(package_data[:name])
          local_dependencies = local_dependencies.keys.count == 0 ? {} : {ALREADY_MENTIONED_DEPS => [Rdm::Package::DEFAULT_GROUP]}
        else
          uniq_packages.push(package_data[:name])
        end

        local_dependencies.each do |k, v|
          local_dependencies.delete(k)

          if local_dependencies.empty?
            tmp_self_predicate = child_predicate  + CORNER
            tmp_child_predicate = child_predicate + '    '
          else
            tmp_self_predicate = child_predicate  + MIDDLE_CORNER
            tmp_child_predicate = child_predicate + '|   '
          end

          next_package_group = {
            name:   k,
            groups: v
          }

          node.push(*draw(next_package_group, uniq_packages, tmp_self_predicate, tmp_child_predicate))
        end

        node
      end

      private

      def check_params!(package_name:, project_path:)
        raise Rdm::Errors::InvalidParams, "Package name should be specified" if package_name.empty?
        raise Rdm::Errors::InvalidParams, "Project directory should be specified" if project_path.empty?
        raise Rdm::Errors::PackageDoesNotExist, package_name if source.packages[package_name].nil?

        nil
      end

      def source
        @source ||= Rdm::SourceParser.read_and_init_source(Rdm::SourceLocator.locate(@project_path))
      end

      def format_package_name(package_name, package_groups, predicate)
        package_groups.include?(Rdm::Package::DEFAULT_GROUP) ? 
          "#{predicate}#{package_name}" : 
          "#{predicate}#{package_name} (#{package_groups.join(', ')})"
      end

      def recursive_find_dependencies(package_names)
        all_packages = source.packages.values

        deps_package_names = all_packages
          .select {|pkg| package_names.include?(pkg.name)}
          .map(&:local_dependencies)
          .flatten
          .uniq

        extended_package_names = deps_package_names | package_names
        
        return package_names if package_names == extended_package_names
        
        recursive_find_dependencies(extended_package_names)
      end
    end
  end
end