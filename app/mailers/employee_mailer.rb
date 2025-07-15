class EmployeeMailer < ApplicationMailer
  helper :application

  def roster_availability(practitioner_id, start_date, end_date)
    @practitioner = Practitioner.find practitioner_id
    @business = @practitioner.business

    @report = Report::Practitioners::EmployeeRoster.make(
      @business,
      {
        practitioner_id: @practitioner.id,
        start_date: start_date,
        end_date: end_date,
      }
    )

    attachments["employee_roster.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "Employee roster availability",
          template: 'pdfs/employee_roster',
          locals: {
            business: @business,
            report: @report
          }
        )
      )

    mail(business_email_options(@business).merge(
      to: @practitioner.user_email, subject: "Roster availability"
    ))
  end
end

