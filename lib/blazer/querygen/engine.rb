# frozen_string_literal: true

module Blazer
  module Querygen
    # Rails Engine for Blazer::Querygen
    class Engine < ::Rails::Engine
      isolate_namespace Blazer::Querygen

      # Load configuration before Rails initializes
      config.before_initialize do
        Blazer::Querygen.configure unless Blazer::Querygen.configuration
      end

      # Ensure controllers are loaded
      config.eager_load_paths << root.join("app/controllers")

      # Inject routes into Blazer
      initializer "blazer_querygen.routes", after: :add_routing_paths do
        Rails.application.routes.append do
          post "blazer/prompts/run", to: "blazer/prompts#run"
          get "blazer/querygen/health", to: "blazer/prompts#health"
        end
      end

      # Include view helpers in all ActionView contexts
      initializer "blazer_querygen.view_helpers" do
        ActiveSupport.on_load(:action_view) do
          include Blazer::Querygen::ViewHelpers
        end
      end

      # Register asset paths
      initializer "blazer_querygen.assets" do |app|
        app.config.assets.precompile += %w[blazer/querygen/prompts.js] if app.config.respond_to?(:assets)
      end
    end
  end
end
