# == Schema Information
#
# Table name: business_tutorials
#
#  id          :integer          not null, primary key
#  business_id :integer
#  lessons     :text
#  status      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_business_tutorials_on_business_id  (business_id)
#

class BusinessTutorial < ApplicationRecord
  STATUS_COMPLETE = 1

  DEMO_VIDEO = 'https://www.youtube.com/embed/CKB6MlF7CaI'

  TUTORIALS = {
    'Profile' => [
      {
        label: 'Business Profile', video: 'https://www.youtube.com/embed/nR1up5Qu4S8',
        description: "Add business contact details."
      },
      {
        label: 'Practitioner Profile', video: 'https://www.youtube.com/embed/3SE_zPN7agc',
        description: "Add practitioner profile Information."
      },
      {
        label: 'Add Users', video: 'https://www.youtube.com/embed/Mwu5dktbx20',
        description: "Add additional users."
      }
    ],
    'Payments' => [
      {
        label: 'Medipass', video: 'https://www.youtube.com/embed/0TjxnrWT8Es',
        description: "Hicaps mobile payment integration"
      },
      {
        label: 'Stripe', video: 'https://www.youtube.com/embed/DLY1Ti6EBfs',
        description: "Stripe eftpos payment integration"
      },
      {
        label: 'Bank Details', video: 'https://www.youtube.com/embed/nR1up5Qu4S8',
        description: "Add bank details on your business profile"
      }
    ],
    'Appointments' => [
      {
        label: 'Billable Items', video: 'https://www.youtube.com/embed/haRXVgIZ0Bk',
        description: "How much do you get paid?"
      },
      {
        label: 'Appointment Types', video: 'https://www.youtube.com/embed/PF79jkxiDVQ',
        description: "How long do you spend with patients?"
      }
    ],
    'Availability' => [
      {
        label: 'Availability', video: 'https://www.youtube.com/embed/iBjYed9kCp8',
        description: "When are you available?"
      },
      {
        label: 'Service Radius', video: 'https://www.youtube.com/embed/gkSLs-Ba9rQ',
        description: "How far are you prepared to travel?"
      }
    ],
    'Patients And Other Setup' => [
      {
        label: 'Import Patients', video: 'https://www.youtube.com/embed/rnWzsEXV6qA',
        description: "Import patient csv file"
      },
      {
        label: 'Cases', video: 'https://www.youtube.com/embed/ZHkFL0pCNyQ',
        description: "What are cases?"
      },
      {
        label: 'Notifications', video: 'https://www.youtube.com/embed/btaGarQOM',
        description: "Do you want practitioner notifications?"
      }
    ],
    'Subscriptions' => [
      {
        label: 'Add Credit Card', video: 'https://www.youtube.com/embed/0TjxnrWT8Es',
        description: "Add your credit card to our system?"
      },
      {
        label: 'Select Subscription', video: 'https://www.youtube.com/embed/DpAzdWpeq6Q',
        description: "What Subscription plan do you need?"
      }
    ]
  }

  serialize :lessons, type: Hash

  belongs_to :business

  def completed?
    self.status == STATUS_COMPLETE
  end
end
