# frozen_string_literal: true

Rails.application.routes.draw do
  mount Blazer::Engine, at: "/blazer"
  root to: redirect("/blazer")
end
