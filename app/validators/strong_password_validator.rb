class StrongPasswordValidator < ActiveModel::EachValidator
  REGEX = %r{^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).}

  def validate_each(record, attr, value)
    if value.present? && !(value =~ REGEX)
      record.errors.add(attr, options[:message] || 'must contain at least one number and one uppercase and lowercase letter')
    end
  end
end
