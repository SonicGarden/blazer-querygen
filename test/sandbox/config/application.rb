# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

require "propshaft"
require "blazer"
require "blazer/querygen"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.1
    config.eager_load = false
    config.secret_key_base = "dummy-app-secret-key-base-for-development-only"
  end
end
