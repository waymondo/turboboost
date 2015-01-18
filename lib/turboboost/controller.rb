module Turboboost
  module Controller
    extend ActiveSupport::Concern

    CATCHABLE_ERRORS = {
      'EOFError'                            => 500,
      'Errno::ECONNRESET'                   => 500,
      'Errno::EINVAL'                       => 500,
      'Timeout::Error'                      => :request_timeout,
      'Net::HTTPBadResponse'                => 500,
      'Net::HTTPHeaderSyntaxError'          => 500,
      'Net::ProtocolError'                  => 500,
      'ActiveRecord::RecordNotFound'        => :not_found,
      'ActiveRecord::StaleObjectError'      => :conflict,
      'ActiveRecord::RecordInvalid'         => :unprocessable_entity,
      'ActiveRecord::RecordNotSaved'        => :unprocessable_entity,
      'ActiveModel::StrictValidationFailed' => :unprocessable_entity,
      'ActiveModel::MissingAttributeError'  => :unprocessable_entity
    }

    included do
      send :rescue_from, *(CATCHABLE_ERRORS.keys), with: :turboboost_error_handler
    end

    def turboboost_error_handler(error)
      if request.xhr? && request.headers['HTTP_X_TURBOBOOST']
        error_status = CATCHABLE_ERRORS[error.class.name]
        response.headers['X-Turboboosted'] = '1'
        if defined?(error.record)
          render_turboboost_errors_for(error.record)
        else
          translation = I18n.t("turboboost.errors.#{error.class.name}")
          message = translation.match('translation missing: (.+)') ? error.class.name : translation
          render json: [message], status: error_status || 500, root: false
        end
      else
        raise error
      end
    end

    def render_turboboost_errors_for(record)
      render json: record.errors.full_messages.to_a, status: :unprocessable_entity, root: false
    end

    def head_turboboost_success(turboboost_flash = {})
      turboboost_flash = _turboboost_get_flash_messages(turboboost_flash)
      head :ok, 'X-Flash' => turboboost_flash.to_json, 'X-Turboboosted' => '1'
    end

    def render(*args, &block)
      if request.xhr? && request.headers['HTTP_X_TURBOBOOST']
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
      response.headers['X-Flash'] = flash.to_hash.to_json unless flash.empty?
      response.headers['X-Turboboosted'] = '1'
      self.response_body = render_to_body(options)
    end

    def redirect_to(options = {}, response_status_and_flash = {})
      if request.xhr? && request.headers['HTTP_X_TURBOBOOST']
        turboboost_redirect_to(options, response_status_and_flash)
      else
        super
      end
    end

    def turboboost_redirect_to(options = {}, response_status_and_flash = {})
      raise ActionControllerError.new('Cannot redirect to nil!') unless options
      raise AbstractController::DoubleRenderError if response_body

      # set flash for turbo redirect headers
      turboboost_flash = _turboboost_get_flash_messages(response_status_and_flash)

      if Rails.version < '4.2'
        self.location = _compute_redirect_to_location(options)
      else
        self.location = _compute_redirect_to_location(request, options)
      end

      head :ok, 'X-Flash' => turboboost_flash.to_json

      flash.update(turboboost_flash) # set flash for rendered view
    end

    def _turboboost_get_flash_messages(response_status_and_flash = {})
      turboboost_flash = {}
      flash_types = defined?(self.class._flash_types) ? self.class._flash_types : [:alert, :notice]
      flash_types.each do |flash_type|
        if type = flash.delete(type)
          turboboost_flash.update(type)
        end
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
end
