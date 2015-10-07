module Turboboost
  # borrowed from - https://github.com/fs/turboforms/blob/master/lib/turboforms.rb
  module FormHelper
    extend ActiveSupport::Concern

    included do
      alias_method_chain :form_for, :data_turboboost
      alias_method_chain :form_tag, :data_turboboost
    end

    def form_for_with_data_turboboost(record_or_name_or_array, *args, &proc)
      options = args.extract_options!

      if options.key?(:turboboost) && options.delete(:turboboost)
        options[:html] ||= {}
        options[:html]['data-turboboost'] = true
        options[:remote] = true
      end

      form_for_without_data_turboboost(record_or_name_or_array, *(args << options), &proc)
    end

    def form_tag_with_data_turboboost(url_for_options={}, *args, &proc)
      options = args.extract_options!

      if options.key?(:turboboost) && options.delete(:turboboost)
        options[:data] ||= {}
        options[:data]['turboboost'] = true
        options[:remote] = true
      end

      form_tag_without_data_turboboost(url_for_options, *(args << options), &proc)
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
