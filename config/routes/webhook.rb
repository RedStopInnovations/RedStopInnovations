Rails.application.routes.draw do
  post 'webhook_subscriptions' => 'webhook_subscriptions#create'
  delete 'webhook_subscriptions' => 'webhook_subscriptions#destroy'
end
