# == Schema Information
#
# Table name: imports
#
#  id                 :integer          not null, primary key
#  name               :string
#  date_added         :datetime
#  business_id        :integer
#  uploaded_file_name :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_imports_on_business_id  (business_id)
#

class Import < ApplicationRecord
end
