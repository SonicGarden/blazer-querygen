# frozen_string_literal: true

class Order < ApplicationRecord
  enum :status, { pending: 0, processing: 1, shipped: 2, delivered: 3, cancelled: 4 }
  enum :priority, { low: 0, medium: 1, high: 2 }

  belongs_to :user
  has_many :order_items, dependent: :destroy
end
