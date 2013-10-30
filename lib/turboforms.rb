require 'turboforms/version'

module Turboforms

  module Controller
    extend ActiveSupport::Concern

    included do
      send :rescue_from, Exception, with: :turboforms_error_handler
    end

    def turboforms_error_handler(exception)
      if request.xhr? and request.headers['HTTP_X_TURBOFORMS']
        if defined?(exception.record)
          render_turboforms_error(exception.record)
        else
          render_turboforms_generic_error(exception)
        end
      end
    end

    def render_turboforms_error(record)
      render json: record.errors.full_messages.to_json, status: :unprocessable_entity
    end

    def render_turboforms_generic_error(exception)
      render json: exception.message.to_json, status: :internal_server_error
    end

    def redirect_to(options={}, response_status_and_flash={})
      if request.xhr? and request.headers['HTTP_X_TURBOFORMS']
        turboform_redirect_to(options, response_status_and_flash)
      else
        super
      end
    end

    def turboform_redirect_to(options={}, response_status_and_flash={})
      raise ActionControllerError.new("Cannot redirect to nil!") unless options
      raise AbstractController::DoubleRenderError if response_body

      # set flash for turbo redirect headers
      turboform_flash = {}
      flash_types = defined?(self.class._flash_types) ? self.class._flash_types : [:alert, :notice]
      flash_types.each do |flash_type|
        if type = response_status_and_flash.delete(flash_type)
          turboform_flash[flash_type] = type
        end
      end
      if other_flashes = response_status_and_flash.delete(:flash)
        turboform_flash.update(other_flashes)
      end

      self.location = _compute_redirect_to_location(options)
      head :ok, "X-Flash" => turboform_flash.to_json

      flash.update(turboform_flash) # set flash for rendered view

    end

  end

  module FormHelper
    extend ActiveSupport::Concern

    included do
      alias_method_chain :form_for, :data_turboform
      alias_method_chain :form_tag, :data_turboform
    end

    def form_for_with_data_turboform(record_or_name_or_array, *args, &proc)
      options = args.extract_options!

      if options.has_key?(:turboform) && options.delete(:turboform)
        options[:html] ||= {}
        options[:html]["data-turboform"] = true
        options[:remote] = true
      end

      form_for_without_data_turboform(record_or_name_or_array, *(args << options), &proc)
    end

    def form_tag_with_data_turboform(record_or_name_or_array, *args, &proc)
      options = args.extract_options!

      if options.has_key?(:turboform) && options.delete(:turboform)
        options[:data] ||= {}
        options[:data]["turboform"] = true
        options[:remote] = true
      end

      form_tag_without_data_turboform(record_or_name_or_array, *(args << options), &proc)
    end
  end

  class Engine < Rails::Engine
    initializer :turboforms do

       ActionView::Base.send :include, Turboforms::FormHelper
       ActiveSupport.on_load(:action_controller) do
         include Turboforms::Controller
       end

     end
  end

end
