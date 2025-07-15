json.extract! product, :id, :name, :item_code, :tax_id

json.set! :price, product.price.to_f

json.tax do
  if product.tax
    json.extract! product.tax, :id, :name, :rate
  end
end