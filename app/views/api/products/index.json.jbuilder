json.products do
  json.array! @products, partial: 'api/products/product', as: :product
end
