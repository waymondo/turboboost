require 'turboboost/controller'
require 'turboboost/form_helper'
require 'turboboost/version'

module Turboboost
  class Engine < Rails::Engine
    initializer :turboboost do
      ActionView::Base.send :include, Turboboost::FormHelper
    end
  end
end

ActiveSupport.on_load(:action_controller) do
  include Turboboost::Controller
end
