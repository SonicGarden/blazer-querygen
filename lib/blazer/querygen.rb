# frozen_string_literal: true

require_relative "querygen/version"
require_relative "querygen/configuration"
require_relative "querygen/ai_client"
require_relative "querygen/schema_extractor"
require_relative "querygen/prompt_builder"
require_relative "querygen/query_generator"
require_relative "querygen/view_helpers" if defined?(Rails)
require_relative "querygen/engine" if defined?(Rails)

module Blazer
  module Querygen
    class Error < StandardError; end

    class << self
      attr_accessor :configuration

      def configure
        self.configuration ||= Configuration.new
        yield(configuration) if block_given?
        configuration
      end

      def config
        configuration || configure
      end
    end
  end
end
