class ApplicationController < ActionController::Base
  ESBUILD_ERROR_RENDERED = Rails.env.development?
  include RenderEsbuildErrors if ESBUILD_ERROR_RENDERED

  before_action do
    if Rails.env.production? && current_user.present?
      Honeybadger.context(user_id: current_user.id, user_email: current_user.email)
    end
  end

  def current_user
    nil # devise
  end

  before_action :enable_rack_profiler

  helper_method :display_dev_info?, :user_root_url, :controller_namespace

  def append_info_to_payload(payload)
    super
    payload[:ip] = forwarded_ip_address
  end

  def forwarded_ip_address
    @forwarded_ip_address ||= ForwardedIpAddress.parse(request)
  end

  def enable_rack_profiler
    return false if !current_user&.developer? || Rails.env.test?
    Rack::MiniProfiler.authorize_request
  end

  def display_dev_info?
    return @display_dev_info if defined?(@display_dev_info)
    # Tie display_dev_info to the rack mini profiler display
    @display_dev_info = !Rails.env.test? && current_user&.developer? &&
      Rack::MiniProfiler.current.present?
  end

  def user_root_url
    return root_url if current_user.blank?
    root_url # TODO: make this something else
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || user_root_url
  end

  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource) || user_root_url
  end

  def controller_namespace
    @controller_namespace ||= (self.class.module_parent.name != "Object") ? self.class.module_parent.name.downcase : nil
  end
end
