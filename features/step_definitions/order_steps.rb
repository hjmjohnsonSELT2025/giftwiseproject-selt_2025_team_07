When("I visit the orders page") do
  visit orders_path
end

When("I place an order with delivery info") do
  page.driver.post(orders_path, {
    delivery_address: "456 Cuke St",
    delivery_phone: "+1 (444) 555-6666",
    delivery_note: "Call me"
  })
  visit orders_path
end
