# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'health_checks#index'

  resources :playthroughs do
    resources :wish_lists, shallow: true, except: %i[show] do
      resources :wish_list_items, shallow: true, except: %i[index show]
    end

    resources :inventory_lists, shallow: true, except: %i[show] do
      resources :inventory_items, shallow: true, except: %i[index show]
    end
  end

  get '/privacy', to: 'utilities#privacy'
  get '/tos', to: 'utilities#tos'
end
