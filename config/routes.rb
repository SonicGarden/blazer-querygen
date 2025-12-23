# frozen_string_literal: true

Blazer::Querygen::Engine.routes.draw do
  scope module: "blazer" do
    # Query generation endpoints
    post "prompts/run", to: "prompts#run", as: :run_prompt

    # Health check endpoint
    get "querygen/health", to: "prompts#health", as: :querygen_health
  end
end
