module Admin
  class CoursesController < BaseController
    before_action do
      authorize! :manage, Course
    end

    before_action :set_course, only: [:show, :edit, :update, :destroy]

    def index
      @search_query = Course.ransack(params[:q].try(:to_unsafe_h))

      @courses = @search_query.
                  result.
                  order(id: :desc).
                  page(params[:page])
    end

    def show
    end

    def new
      @course = Course.new
    end

    def edit
    end

    def create
      @course = Course.new(course_params)

      if @course.save
        redirect_to admin_course_path(@course), notice: 'Course was successfully created.'
      else
        render :new
      end
    end

    def update
      if @course.update(course_params)
        redirect_to admin_course_path(@course), notice: 'Course was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @course.destroy
      redirect_to admin_courses_url, notice: 'Course was successfully deleted.'
    end

    private

    def set_course
      @course = Course.find(params[:id])
    end

    def course_params
      params.require(:course).permit(
        :title,
        :video_url,
        :presenter_full_name,
        :course_duration,
        :cpd_points,
        :description,
        :reflection_answer,
        :seo_page_title,
        :seo_description,
        :seo_metatags,
        :thumbnail,
        profession_tags: []
      )
    end
  end
end
