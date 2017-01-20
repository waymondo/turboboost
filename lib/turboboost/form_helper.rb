module Turboboost
  module FormHelper
    extend ActiveSupport::Concern

    def form_for(record_or_name_or_array, *args, &proc)
      options = args.extract_options!
      if options.key?(:turboboost) && options.delete(:turboboost)
        options[:html] ||= {}
        options[:html]['data-turboboost'] = true
        options[:remote] = true
      end
      super(record_or_name_or_array, *(args << options), &proc)
    end

    def form_tag(url_for_options = {}, *args, &proc)
      options = args.extract_options!
      if options.key?(:turboboost) && options.delete(:turboboost)
        options[:data] ||= {}
        options[:data]['turboboost'] = true
        options[:remote] = true
      end
      super(url_for_options, *(args << options), &proc)
    end

    def convert_options_to_data_attributes(options, html_options)
      if html_options
        html_options = html_options.stringify_keys
        if html_options.delete('turboboost')
          html_options['data-remote'] = 'true'
          html_options['data-turboboost'] = 'true'
        end
      end
      super options, html_options
    end
  end
end
