module Slugifyer
  extend Functionable

  def slugify(string)
    return nil unless string.present?
    # First, remove diacritics, downcase and strip
    I18n.transliterate(string.to_s.downcase).strip
      .gsub(/\(|\)/, "").strip # Remove parentheses
      .gsub(/https?:\/\//, "") # remove http://
      .gsub(/(\s|-|\+|_)+/, "-") # Replace spaces with -
      .gsub(/-?&(amp;)?-?/, "-amp-") # Replace singular & with amp - since we permit & in names
      .gsub(/([^A-Za-z0-9_-]+)/, "-").squeeze("-") # Remove any lingering double -
      .gsub(/(\s|-|\+|_)+/, "-") # Replace spaces and underscores with -
      .gsub("-&-", "-amp-").squeeze("-") # Remove lingering double -
      .delete_prefix("-").delete_suffix("-") # remove leading and trailing -
  end

  def slugify_and(string)
    slugify(string)&.gsub("-amp-", "-and-")
      &.gsub("-amp-", "-and-")
  end
end
