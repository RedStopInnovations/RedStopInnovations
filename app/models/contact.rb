# == Schema Information
#
# Table name: contacts
#
#  id                     :integer          not null, primary key
#  contact_type           :string
#  business_name          :string
#  title                  :string
#  first_name             :string
#  last_name              :string
#  company_name           :string
#  phone                  :string
#  mobile                 :string
#  fax                    :string
#  email                  :string
#  address1               :string
#  address2               :string
#  address3               :string
#  city                   :string
#  state                  :string
#  postcode               :string
#  country                :string
#  archived_at            :datetime
#  updated_at             :datetime         not null
#  updated_at             :datetime         not null
#  business_id            :integer
#  notes                  :text
#  deleted_at             :datetime
#  latitude               :float
#  longitude              :float
#  full_name              :string
#  metadata               :jsonb
#  important_notification :text
#
# Indexes
#
#  index_contacts_on_business_id  (business_id)
#

class Contact < ApplicationRecord
  include RansackAuthorization::Contact
  include HasAddressGeocoding
  include DeletionRecordable

  TYPES = [
    'Standard'
  ]

  acts_as_paranoid
  auto_strip_attributes :title, :business_name, :first_name, :last_name, squish: true

  has_paper_trail(
    only: [
      :business_name, :title, :first_name, :last_name, :email,
      :address1, :address2, :address3, :city, :state, :postcode, :country,
      :archived_at
    ],
    on: [:create, :update, :destroy],
    versions: {
      class_name: 'PaperTrailVersion'
    }
  )

  has_and_belongs_to_many :availabilities
  has_many :appointments, through: :availabilities
  has_many :pricing_billable_items, class_name: "BillableItemsContacts",
                              foreign_key: 'contact_id',
                              inverse_of: :contact
  belongs_to :business

  has_many :communications
  has_many :patient_contacts
  has_many :patients, through: :patient_contacts
  has_many :invoices, foreign_key: :invoice_to_contact_id
  has_many :payment_allocations, through: :invoices
  has_many :payments, through: :payment_allocations
  has_many :account_statements, as: :source

  validates_presence_of :business_name

  validates :email,
            email: true,
            length: { maximum: 255 },
            allow_nil: true,
            allow_blank: true

  validates :business_name,
            presence: true,
            length: { maximum: 100 }

  validates :first_name, :last_name,
            length: { maximum: 25 },
            allow_nil: true,
            allow_blank: true

  validates :title,
            length: { maximum: 30 },
            allow_nil: true,
            allow_blank: true

  validates_length_of :phone, :mobile, :fax, :address1, :address2, :city, :state,
            :postcode,
            :country, maximum: 255

  validates_length_of :notes, maximum: 1000


  before_save :set_full_name_attr

  scope :not_archived, -> { where(archived_at: nil) }

  private

  def set_full_name_attr
    if first_name_changed? || last_name_changed?
      self.full_name = [
        first_name.to_s.strip.presence,
        last_name.to_s.strip.presence
      ].compact.join(' ').strip
    end
  end
end
