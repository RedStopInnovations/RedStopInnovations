class Ability
  include CanCan::Ability

  # @TODO: remove this when use a newer version of cancancan(> 1.15)
  def unauthorized_message(action, subject)
    keys = unauthorized_message_keys(action, subject)
    variables = {action: action.to_s}
    variables[:subject] = (subject.class == Class ? subject : subject.class).to_s.underscore.humanize.downcase
    message = I18n.translate(nil, **variables.merge(scope: :unauthorized, default: keys + [""]))
    message.blank? ? nil : message
  end

  def initialize(user)
    user ||= User.new

    if user.persisted?
      if user.is_practitioner?
        can :read, Referral
      end

      if user.role_administrator?
        can :manage, :all

        cannot :edit, Treatment do |treatment|
          treatment.status == Treatment::STATUS_FINAL
        end

      elsif user.role_supervisor?
        [
          Patient, Contact, Invoice, Payment, Availability, Appointment,
          Communication, Treatment, PatientLetter,
          AccountStatement, PatientCase, Referral
        ].
          each do |resource|
          can :manage, resource
        end
        can :manage, :calendar
        can :manage, Task
        can :read, :reports
        can :read, :treatment_note_reports

        # Review bellow abilities
        can :manage_access, Patient
        can :merge, Contact
        can :merge, Patient
        can :destroy, Patient
        can :destroy, Invoice
        can :export, Patient
        can :export, :all

      elsif user.role_restricted_supervisor?
        [
          Patient, Contact, Invoice, Payment, Availability, Appointment,
          Communication, Treatment, PatientLetter,
          AccountStatement, PatientCase, Referral
        ].
          each do |resource|
          can :manage, resource
        end
        can :manage, :calendar
        can :manage, Task

        # Review bellow abilities
        can :manage_access, Patient
        can :merge, Contact
        can :merge, Patient
        can :destroy, Patient
        can :destroy, Invoice
        can :export, Patient
        can :export, :all
      elsif user.role_practitioner?
        [
          Patient, Contact, Invoice, Payment, Availability, Appointment,
          Treatment, PatientLetter, AccountStatement, PatientCase
        ].
          each do |resource|
          can :manage, resource
        end

        can :read, Communication

        can [:edit, :update, :destroy], Post do |post|
          post.practitioner_id == user.practitioner.try(:id)
        end

        can :manage, :calendar
        can :read, Product

        can [:edit, :update, :destroy], Task do |task|
          task.owner_id == user.id
        end

        cannot :manage, User
        cannot :export, Patient
        cannot :destroy, Patient
        cannot :destroy, Payment
        cannot :read, Payment
        cannot :destroy, Invoice
        cannot :manage_access, Patient
        cannot :read, :reports
        cannot :read, :settings
        cannot :edit, :business_profile
        cannot :destroy, Treatment
        cannot :merge, Contact
        cannot :merge, Patient

        cannot :edit, Treatment do |treatment|
          treatment.status == Treatment::STATUS_FINAL
        end

        cannot :edit, Invoice
      elsif user.role_restricted_practitioner?
        [Patient, Availability, Appointment, Treatment, PatientLetter].
          each do |resource|
          can :manage, resource
        end

        can :manage, :calendar
        can :read, Product

        can [:edit, :update, :destroy], Task do |task|
          task.owner_id == user.id
        end

        cannot :manage, User
        cannot :export, Patient
        cannot :destroy, Patient
        cannot :manage_access, Patient
        cannot :read, :reports
        cannot :read, :settings
        cannot :edit, :business_profile
        cannot :destroy, Treatment
        cannot :destroy, Payment
        cannot :destroy, Invoice
        cannot :read, Payment
        cannot :read, Contact
        cannot :search, Availability
        cannot :merge, Contact
        cannot :merge, Patient

        cannot :edit, Treatment do |treatment|
          treatment.status == Treatment::STATUS_FINAL
        end

        cannot :edit, Invoice
      elsif user.role_receptionist?
        [Patient, Invoice, Payment, Availability, Appointment, Communication].
          each do |resource|
          can :manage, resource
        end
        can :manage, :calendar
        can :read, :reports
        can :read, Contact
        can [:read, :create, :edit, :update], Referral
        can :create, Contact
        can :update, Contact

        can [:edit, :update], Task do |task|
          task.owner_id == user.id
        end

        cannot :read, Post
        cannot :export, Patient
        cannot :read, :settings
        cannot :read, Treatment
        cannot :read, PatientLetter
        cannot :destroy, Patient
        cannot :manage_access, Patient
        cannot :edit, Invoice
        cannot :destroy, Payment
        cannot :read, Payment
        cannot :destroy, Invoice
        cannot :merge, Contact
        cannot :merge, Patient
      elsif user.role_virtual_receptionist?
        cannot :read, :calendar
        cannot :read, :reports
        cannot :read, Contact
        cannot :read, Referral
        cannot :read, Contact
        cannot :read, Task
        cannot :read, Post
        cannot :export, Patient
        cannot :read, :settings
        cannot :read, Treatment
        cannot :read, PatientLetter
        cannot :destroy, Patient
        cannot :manage_access, Patient
        cannot :edit, Invoice
        cannot :destroy, Payment
        cannot :read, Payment
        cannot :destroy, Invoice
        cannot :merge, Contact
        cannot :merge, Patient
      end
    end
  end
end
