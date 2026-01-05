# frozen_string_literal: true

require "rails/generators"

module Blazer
  module Querygen
    module Generators
      # Generator for installing Blazer::Querygen
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        desc "Creates Blazer::Querygen initializer and optionally Blazer layout"

        class_option :skip_layout, type: :boolean, default: false,
                                   desc: "Skip creating Blazer layout (you'll need to add JavaScript manually)"

        def copy_initializer
          template "initializer.rb", "config/initializers/blazer_querygen.rb"
        end

        def create_blazer_layout
          if options[:skip_layout]
            say "Skipped layout creation. You'll need to manually include JavaScript.", :yellow
          else
            template "blazer_layout.html.erb", "app/views/layouts/blazer/application.html.erb"
            say "Created Blazer layout with Querygen JavaScript included", :green
          end
        end

        def show_readme
          readme "README" if behavior == :invoke
        end
      end
    end
  end
end
