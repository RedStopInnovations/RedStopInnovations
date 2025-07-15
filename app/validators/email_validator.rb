class EmailValidator < ActiveModel::EachValidator
  REGEX = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

  def self.valid?(email)
    email =~ REGEX
  end

  def validate_each(record, attr, value)
    unless value =~ REGEX
      record.errors.add(attr, options[:message] || 'is not valid email')
    end
  end
end
