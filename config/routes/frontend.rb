Rails.application.routes.draw do
  scope module: 'frontend', as: 'frontend' do
    get '/' => 'pages#home', as: :home
  end
end
