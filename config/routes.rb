Rails.application.routes.draw do
  get 'welcome/index'

  resources :members
  get '/members/:id/find', to: 'members#find_topic', as: 'find'
  root 'welcome#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
