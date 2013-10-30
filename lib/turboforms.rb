require 'turboforms/version'

module Turboforms

  module Controller
    extend ActiveSupport::Concern

    included do
      send :rescue_from, Exception, with: :turboforms_error_handler
      send :rescue_from, "ActiveRecord::RecordInvalid", with: :turboforms_error_handler
    end

    def turboforms_error_handler(exception)
      if request.xhr? and request.headers['HTTP_X_TURBOFORMS'] and exception.record
        render_turboforms_error(exception.record)
      end
    end

    def render_turboforms_error(record)
      render json: record.errors.full_messages.to_json, status: :unprocessable_entity
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

      self.location = _compute_redirect_to_location(options)
      head :ok, response_status_and_flash.merge(location: self.location)

      # set flash for turbo redirect
      self.class._flash_types.each do |flash_type|
        if type = response_status_and_flash.delete(flash_type)
          flash[flash_type] = type
        end
      end
      if other_flashes = response_status_and_flash.delete(:flash)
        flash.update(other_flashes)
      end
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
