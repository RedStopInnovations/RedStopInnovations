class ReviewsController < ApplicationController
  layout 'frontend/layouts/minimal'

  def new
    @appointment = Appointment.find_by(public_token: params[:appointment_token])

    if @appointment
      if Review.exists?(practitioner_id: @appointment.practitioner_id, patient_id: @appointment.patient_id)
        redirect_to frontend_home_url, alert: 'You have already given a review for the practitioner.'
      else
        @practitioner = @appointment.practitioner
        @review_form = AppointmentReviewForm.new

        render :new
      end
    else
      redirect_to frontend_home_url
    end
  end

  def create
    @appointment = Appointment.find_by(public_token: params[:appointment_token])

    if !@appointment || Review.exists?(practitioner_id: @appointment.practitioner_id, patient_id: @appointment.patient_id)
      redirect_to frontend_home_url, alert: 'You have already given a review for the practitioner.'
    else
      @practitioner = @appointment.practitioner
      @review_form = AppointmentReviewForm.new(review_params)

      if @review_form.valid?
        review = Review.new(
          source_appointment_id: @appointment.id,
          practitioner_id: @appointment.practitioner_id,
          patient_id: @appointment.patient_id,
          comment: @review_form.comment,
          rating: @review_form.score,
        )
        review.patient_name = @appointment.patient.full_name
        review.save!(validate: false)
        ReviewMailer.review_submitted_email(review).deliver_later

        render :success
      else
        @practitioner = @appointment.practitioner
        render :new
      end
    end
  end

  def success; end

  private

  def review_params
    params.require(:review).permit(
      :score,
      :comment
    )
  end
end
