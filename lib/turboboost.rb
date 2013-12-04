require 'turboboost/version'

CATCHABLE_ERRORS = {
  "EOFError"                            => 500,
  "Errno::ECONNRESET"                   => 500,
  "Errno::EINVAL"                       => 500,
  "Timeout::Error"                      => :request_timeout,
  "Net::HTTPBadResponse"                => 500,
  "Net::HTTPHeaderSyntaxError"          => 500,
  "Net::ProtocolError"                  => 500,
  "ActiveRecord::RecordNotFound"        => :not_found,
  "ActiveRecord::StaleObjectError"      => :conflict,
  "ActiveRecord::RecordInvalid"         => :unprocessable_entity,
  "ActiveRecord::RecordNotSaved"        => :unprocessable_entity,
  "ActiveModel::StrictValidationFailed" => :unprocessable_entity,
  "ActiveModel::MissingAttributeError"  => :unprocessable_entity
}

module Turboboost

  module Controller
    extend ActiveSupport::Concern

    included do
      send :rescue_from, *(CATCHABLE_ERRORS.keys), with: :turboboost_error_handler
    end

    def turboboost_error_handler(error)
      if request.xhr? and request.headers['HTTP_X_TURBOBOOST']
        error_status = CATCHABLE_ERRORS[error.class.name]
        if defined?(error.record)
          render_turboboost_errors_for(error.record)
        else
          render json: [error.message], status: error_status || 500
        end
      else
        raise error
      end
    end

    def render_turboboost_errors_for(record)
      render json: record.errors.full_messages.to_a, status: :unprocessable_entity, root: false
    end

    def head_turboboost_success(turboboost_flash={})
      turboboost_flash = _turboboost_get_flash_messages(turboboost_flash)
      head :ok, "X-Flash" => turboboost_flash.to_json
    end

    def render(*args, &block)
      if request.xhr? and request.headers['HTTP_X_TURBOBOOST']
        turboboost_render(*args, &block)
      else
        super
      end
    end

    def turboboost_render(*args, &block)
      options = _normalize_render(*args, &block)
      [:replace, :within, :append, :prepend].each do |h|
        response.headers["X-#{h.capitalize}"] = options[h] if options[h]
      end
      self.response_body = render_to_body(options)
    end

    def redirect_to(options={}, response_status_and_flash={})
      if request.xhr? and request.headers['HTTP_X_TURBOBOOST']
        turboboost_redirect_to(options, response_status_and_flash)
      else
        super
      end
    end

    def turboboost_redirect_to(options={}, response_status_and_flash={})
      raise ActionControllerError.new("Cannot redirect to nil!") unless options
      raise AbstractController::DoubleRenderError if response_body

      # set flash for turbo redirect headers
      turboboost_flash = _turboboost_get_flash_messages(response_status_and_flash)

      self.location = _compute_redirect_to_location(options)
      head :ok, "X-Flash" => turboboost_flash.to_json

      flash.update(turboboost_flash) # set flash for rendered view
    end

    def _turboboost_get_flash_messages(response_status_and_flash={})
      turboboost_flash = {}
      flash_types = defined?(self.class._flash_types) ? self.class._flash_types : [:alert, :notice]
      flash_types.each do |flash_type|
        if type = response_status_and_flash.delete(flash_type)
          turboboost_flash[flash_type] = type
        end
      end
      if other_flashes = response_status_and_flash.delete(:flash)
        turboboost_flash.update(other_flashes)
      end
      turboboost_flash
    end

  end

  # borrowed from - https://github.com/fs/turboforms/blob/master/lib/turboforms.rb
  module FormHelper
    extend ActiveSupport::Concern

    included do
      alias_method_chain :form_for, :data_turboboost
      alias_method_chain :form_tag, :data_turboboost
    end

    def form_for_with_data_turboboost(record_or_name_or_array, *args, &proc)
      options = args.extract_options!

      if options.has_key?(:turboboost) && options.delete(:turboboost)
        options[:html] ||= {}
        options[:html]["data-turboboost"] = true
        options[:remote] = true
      end

      form_for_without_data_turboboost(record_or_name_or_array, *(args << options), &proc)
    end

    def form_tag_with_data_turboboost(record_or_name_or_array, *args, &proc)
      options = args.extract_options!

      if options.has_key?(:turboboost) && options.delete(:turboboost)
        options[:data] ||= {}
        options[:data]["turboboost"] = true
        options[:remote] = true
      end

      form_tag_without_data_turboboost(record_or_name_or_array, *(args << options), &proc)
    end

    def convert_options_to_data_attributes(options, html_options)
      if html_options
        html_options = html_options.stringify_keys
        if turboboost = html_options.delete("turboboost")
          html_options["data-remote"] = "true"
          html_options["data-turboboost"] = "true"
        end
      end
      super options, html_options
    end

  end

  class Engine < Rails::Engine
    initializer :turboboost do
       ActionView::Base.send :include, Turboboost::FormHelper
     end
  end

end

# ActionView::Base.send :include, Turboboost::FormHelper
ActiveSupport.on_load(:action_controller) do
  include Turboboost::Controller
end
