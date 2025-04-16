# frozen_string_literal: true

module SortableHelper
  DEFAULT_SEARCH_KEYS = %i[direction sort period start_time end_time per_page user_id query].freeze

  def sortable(column, title = nil, html_options = {})
    if title.is_a?(Hash) # If title is a hash, it wasn't passed
      html_options = title
      title = nil
    end

    title ||= column.gsub(/_(id|at)\z/, "").titleize
    # Check for render_sortable - otherwise default to rendering
    render_sortable = html_options.key?(:render_sortable) ? html_options[:render_sortable] : !html_options[:skip_sortable]
    return title unless render_sortable

    html_options[:class] = "#{html_options[:class]} sortable-link"
    direction = (column == sort_column && sort_direction == "desc") ? "asc" : "desc"
    if column == sort_column
      html_options[:class] += " active"
      span_content = (direction == "asc") ? "\u2193" : "\u2191"
    end

    link_to(sortable_search_params.merge(sort: column, direction: direction), html_options) do
      concat(title.html_safe)
      concat(content_tag(:span, span_content, class: "sortable-direction"))
    end
  end

  def sortable_params
    @sortable_params ||= sortable_search_params.as_json.map do |k, v|
      # Skip default sort parameters, to reduce unnecessary params
      next if v.blank? || k == "sort" && v == default_column ||
        k == "sort_direction" && v == default_direction
      [k, v]
    end.compact.to_h.with_indifferent_access
  end

  def sortable_search_params
    search_param_keys = params.keys.select { |k| k.to_s.start_with?("search_") }
    params.permit(*(DEFAULT_SEARCH_KEYS | search_param_keys))
  end

  def sortable_search_params_without_sort
    sortable_search_params.except(:direction, :sort)
  end

  def sortable_search_params?(except: [])
    except_keys = %i[direction sort period per_page] + except
    s_params = sortable_search_params.except(*except_keys).values.reject(&:blank?).any?

    return true if s_params
    return false if except.map(&:to_s).include?("period")
    params[:period].present? && params[:period] != "all"
  end
end
