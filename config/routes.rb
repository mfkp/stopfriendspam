Spammyfriends::Application.routes.draw do
  root :to => "home#index"

  # facebook auth
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'signout', to: 'sessions#destroy', as: 'signout'

  # main routes
  get '/', to: 'home#index'
  get '/find', to: 'home#find'
end
