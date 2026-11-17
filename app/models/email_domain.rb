# frozen_string_literal: true

module EmailDomain
  # RFC 2606 / 6761 reserved domains, which no message ever arrives at. Also checked
  # client side, so keep it to syntax JS shares -- see UI::Forms::Email::Component.
  RESERVED_REGEX = /
    \A(?:.+\.)?example\.(?:com|net|org)\z |
    (?:\A|\.)(?:test|example|invalid|localhost)\z
  /xi
end
