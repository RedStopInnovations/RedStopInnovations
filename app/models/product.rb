# == Schema Information
#
# Table name: products
#
#  id                 :integer          not null, primary key
#  business_id        :integer          not null
#  name               :string           not null
#  item_code          :string
#  price              :decimal(10, 2)   default(0.0), not null
#  serial_number      :string
#  supplier_name      :string
#  supplier_phone     :string
#  supplier_email     :string
#  notes              :text
#  tax_id             :integer
#  image_file_name    :string
#  image_content_type :string
#  image_file_size    :integer
#  image_updated_at   :datetime
#  xero_account_code  :string
#  deleted_at         :datetime
#
# Indexes
#
#  index_products_on_business_id  (business_id)
#

class Product < ApplicationRecord
  include DeletionRecordable

  belongs_to :business
  belongs_to :tax

  has_attached_file :image,
                    styles: {
                      medium: "300x300>",
                      thumb: "100x100#"
                    }

  has_many :invoice_items, as: :invoiceable

  validates :name,
            presence: true,
            length: { maximum: 150 }

  validates :item_code,
            presence: true,
            length: { maximum: 30 },
            uniqueness: { scope: :business_id }

  validates :price,
            presence: true,
            numericality: { greater_than: 0 }

  validates :serial_number,
            length: { maximum: 100 },
            allow_nil: true,
            allow_blank: true

  validates :supplier_name,
            length: { maximum: 150 },
            allow_nil: true,
            allow_blank: true

  validates :supplier_phone,
            length: { maximum: 20 },
            allow_nil: true,
            allow_blank: true

  validates :supplier_email,
            length: { maximum: 250 },
            allow_nil: true,
            allow_blank: true

  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/
  validates_length_of :notes, maximum: 1000

  delegate :name, :rate, to: :tax, prefix: true, allow_nil: true

  scope :not_deleted, -> { where(deleted_at: nil) }
end
