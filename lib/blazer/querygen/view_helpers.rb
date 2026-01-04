# frozen_string_literal: true

module Blazer
  module Querygen
    # View helpers for including Blazer Querygen JavaScript assets
    #
    # Usage in views/layouts:
    #   <%= blazer_querygen_javascript %>
    #
    # The helper will only load JavaScript if the OpenAI API key is configured.
    # This prevents JavaScript errors when the feature is not properly set up.
    module ViewHelpers
      # Includes Blazer Querygen JavaScript assets
      #
      # Only loads the JavaScript if the OpenAI API key is configured.
      # Handles asset loading errors gracefully.
      #
      # @return [String, nil] JavaScript include tag or nil if not configured
      #
      # @example In application layout
      #   <%= blazer_querygen_javascript %>
      #
      # @example In Blazer layout
      #   <head>
      #     <%= blazer_querygen_javascript %>
      #   </head>
      def blazer_querygen_javascript
        # Only load JavaScript if API key is configured
        return nil unless Blazer::Querygen.config.api_key.present?

        # Load the JavaScript asset with error handling
        begin
          javascript_include_tag("blazer/querygen/prompts")
        rescue StandardError => e
          # Log error but don't break the page
          Rails.logger.error("Failed to load Blazer Querygen JavaScript: #{e.message}") if defined?(Rails)
          nil
        end
      end
    end
  end
end
