# frozen_string_literal: true

class CreateSampleTables < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :role, default: "member"
      t.timestamps
    end

    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2
      t.string :category
      t.integer :stock_count, default: 0
      t.timestamps
    end

    create_table :orders do |t|
      t.references :user, foreign_key: true
      t.integer :status, default: 0
      t.integer :priority, default: 0
      t.decimal :total_amount, precision: 10, scale: 2
      t.timestamps
    end

    create_table :order_items do |t|
      t.references :order, foreign_key: true
      t.references :product, foreign_key: true
      t.integer :quantity, default: 1
      t.decimal :unit_price, precision: 10, scale: 2
      t.timestamps
    end
  end
end
