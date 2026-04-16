class ApplicationController < ActionController::Base
  include Pagy::Method
  include Binxtils::SetPeriod

  self.default_earliest_time = Time.at(1714460400).freeze # 2024-4-30

  before_action :enable_rack_profiler

  before_action do
    if Rails.env.production? && current_user.present?
      Honeybadger.context(user_id: current_user.id)
    end
  end

  helper_method :display_dev_info?, :user_root_url, :controller_namespace

  def append_info_to_payload(payload)
    super
    payload[:ip] = forwarded_ip_address
    payload[:u_id] = current_user&.id
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

  protected

  def per_page
    (params[:per_page].presence || 20).to_i.clamp(1, 100)
  end

  def page
    page_i = (params[:page].presence || 1).to_i
    (page_i > 0) ? page_i : 1
  end

  def redirect_to_root_unless_user_present!
    if current_user.present?
      user_redirect_to = permitted_user_redirect_path(session.delete(:user_return_to))
      if user_redirect_to.present?
        redirect_to(user_redirect_to, status: :see_other)
        return
      end
      return current_user
    end
    store_return_to
    redirect_to root_url, status: :see_other
    false
  end

  def ensure_user_admin!
    if current_user.blank?
      redirect_to_root_unless_user_present!
    elsif !current_user.admin_access?
      flash[:error] = "Not authorized"
      redirect_to user_root_url, status: :see_other
    end
  end

  def controller_namespace
    @controller_namespace ||= (self.class.module_parent.name != "Object") ? self.class.module_parent.name.downcase : nil
  end

  def store_return_to
    return if request.xhr? || not_stored_paths.include?(request.path)
    # Don't overwrite existing unless it's for an admin path
    if session[:user_return_to].blank? || request.path.start_with?("/admin")
      session[:user_return_to] = request.fullpath
    end
    session[:user_return_to]
  end

  def not_stored_paths
    ["/", "/account"]
  end

  # TODO: actually clean things.
  def permitted_user_redirect_path(path = nil)
    return nil if path.blank? || path.start_with?("/")
    path
  end
end
