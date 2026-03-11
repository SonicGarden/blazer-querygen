# frozen_string_literal: true

puts "Seeding database..."

# Users
users = 10.times.map do |i|
  User.create!(
    name: "User #{i + 1}",
    email: "user#{i + 1}@example.com",
    role: %w[admin member member member moderator][i % 5]
  )
end
puts "  Created #{users.size} users"

# Products
categories = %w[Electronics Books Clothing Food]
products = 20.times.map do |i|
  Product.create!(
    name: "Product #{i + 1}",
    description: "Description for product #{i + 1}",
    price: (rand(5.0..200.0)).round(2),
    category: categories[i % categories.length],
    stock_count: rand(0..100)
  )
end
puts "  Created #{products.size} products"

# Orders with items
orders_count = 0
30.times do
  order = Order.create!(
    user: users.sample,
    status: rand(0..4),
    priority: rand(0..2),
    total_amount: 0
  )

  total = 0
  rand(1..4).times do
    product = products.sample
    quantity = rand(1..3)
    total += product.price * quantity
    OrderItem.create!(
      order: order,
      product: product,
      quantity: quantity,
      unit_price: product.price
    )
  end
  order.update!(total_amount: total.round(2))
  orders_count += 1
end
puts "  Created #{orders_count} orders with items"

# Sample Blazer queries
Blazer::Query.create!(
  name: "All Users",
  statement: "SELECT * FROM users ORDER BY created_at DESC",
  data_source: "main"
)
Blazer::Query.create!(
  name: "Orders by Status",
  statement: "SELECT status, COUNT(*) as count FROM orders GROUP BY status",
  data_source: "main"
)
Blazer::Query.create!(
  name: "Top Products by Revenue",
  statement: <<~SQL,
    SELECT p.name, SUM(oi.quantity * oi.unit_price) as revenue
    FROM order_items oi
    JOIN products p ON p.id = oi.product_id
    GROUP BY p.name
    ORDER BY revenue DESC
  SQL
  data_source: "main"
)
puts "  Created 3 sample Blazer queries"

puts "Done!"
