# frozen_string_literal: true

module Blazer
  module Querygen
    # View helpers that automatically inject JavaScript into Blazer pages
    module ViewHelpers
      def self.included(base)
        base.class_eval do
          # Override or extend content_for to inject our JavaScript
          def blazer_querygen_javascript
            javascript_include_tag("blazer/querygen/prompts")
          end
        end
      end
    end
  end
end
