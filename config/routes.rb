# frozen_string_literal: true

Rails.application.routes.draw do
  # /oauth
  use_doorkeeper do
    controllers authorizations: 'authorizations'
  end

  namespace :v1, defaults: { format: :json } do
    # users
    get '/me' => 'users#me'
    put '/me' => 'users#update'
    post '/users/check' => 'users#check'
    post '/users/email' => 'users#email'
    resources :users do
      post 'avatar' => 'users#update_avatar'
      post 'follow' => 'users#follow'
      delete 'follow' => 'users#unfollow'
    end

    # search
    post '/search' => 'search#search'

    # compositions
    get '/me/compositions' => 'compositions#index_by_current_user'
    resources :compositions do
      post '/pages/:page_id' => 'compositions#link_page'
      delete '/pages/:page_id' => 'compositions#unlink_page'
      get '/pages' => 'compositions#index_pages'
      get '/download' => 'compositions#download'
    end

    # pages, components, and compositions
    get '/me/pages' => 'pages#index_by_current_user'
    get '/me/pages/:published' => 'pages#index_by_current_user'
    get '/pages/featured' => 'pages#index_by_featured'
    get '/pages/following' => 'pages#index_by_following'
    get '/users/:user_id/pages' => 'pages#index_by_user'
    get '/users/:user_id/compositions' => 'compositions#index_by_user'
    get '/users/:user_id/components' => 'component_collections#index_by_user'
    resources :pages do
      resources :collections, controller: :component_collections do
        resources :components
      end
      resources :comments, only: %i[index]
    end

    # single use component collections
    get '/me/collections' => 'single_use_component_collections#index_by_user'
    resources :collections, controller: :single_use_component_collections do
      resources :components
    end

    resources :collections, controller: :component_collections

    resources :components do
      post '/upload' => 'components#upload'
      post '/process' => 'components#transcode'
      post '/notify' => 'components#notify'
    end

    # comments
    resources :comments, only: %i[create show update destroy]

    # votes
    resources :votes, only: %i[create update]

    # nods
    resources :nods, only: %i[create destroy]

    # tracks
    resources :tracks, only: %i[create show destroy]

    # animations
    resources :animations, only: %i[create show destroy]

    # /v1/videos
    resources :videos, only: %i[create show destroy]

    # /v1/tags
    resources :tags, only: %i[index]
  end
end
