module Settings
  class BookingsQuestionsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    def index
      @questions = BookingsQuestion.
        not_deleted.
        where(business_id: current_business.id).
        order(order: :asc).
        to_a
      respond_to do |f|
        f.json {
          render json: { questions: @questions }
        }
        f.html
      end
    end

    def update
      respond_to do |f|
        f.json do
          questions = []

          update_params[:questions].each_with_index do |question_attrs, index|
            question = nil
            if question_attrs[:id].present?
              question = BookingsQuestion.not_deleted.
                where(business_id: current_business.id).
                find_by(id: question_attrs[:id])
            end
            sanitized_attrs = question_attrs.slice(:title, :required, :type, :answers)
            if question.nil?
              question = BookingsQuestion.new(
                sanitized_attrs
              )
            else
              question.assign_attributes(sanitized_attrs)
            end

            question.assign_attributes(
              order: index,
              business_id: current_business.id
            )
            question.validate
            questions << question
          end

          if questions.any?(&:invalid?)
            errors = []
            questions.each_with_index do |q, idx|
              if q.invalid?
                errors << {
                  index: idx,
                  errors: q.errors.full_messages
                }
              end
            end
            render(
              json: { errors: errors },
              status: 422
            )
          else
            BookingsQuestion.transaction do
              before_question_ids = BookingsQuestion.
                    not_deleted.
                    where(business_id: current_business.id).
                    pluck(:id)

              after_question_ids = []
              questions.each do |q|
                q.save!(validate: false)
                after_question_ids << q.id
              end


              delete_question_ids = before_question_ids - after_question_ids
              if delete_question_ids.present?
                BookingsQuestion.
                  not_deleted.
                  where(
                    business_id: current_business.id,
                    id: delete_question_ids
                  ).
                  update_all(deleted_at: Time.current)
              end
            end

            @questions = BookingsQuestion.
              not_deleted.
              where(business_id: current_business.id).
              order(order: :asc).
              to_a


            render json: { questions: @questions }
          end
        end
      end

    end

    private

    def update_params
      params.permit(
        questions: [:id, :title, :required, :type, answers: [:content]]
      )
    end
  end
end
