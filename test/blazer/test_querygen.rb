# frozen_string_literal: true

require "test_helper"

class Blazer::TestQuerygen < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Blazer::Querygen::VERSION
  end

  def test_configuration_is_accessible
    assert_respond_to ::Blazer::Querygen, :configure
    assert_respond_to ::Blazer::Querygen, :config
  end
end
