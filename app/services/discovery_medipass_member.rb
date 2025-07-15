class DiscoveryMedipassMember

  def call(patient)
    begin
      result = OpenStruct.new
      res = Medipass::Member.discovery build_discovery_params(patient)
      result[:success] = true
      result.member_id = res['_id']
    rescue Medipass::ApiException => e
      result[:success] = false
      unless e.status_code == 404
        Sentry.set_extras(
          patient_id: patient.id
        )
        Sentry.capture_exception(e)
      end
    end
    result
  end

  private

  def build_discovery_params(patient)
    params = {}
    params[:firstName] = patient.first_name
    params[:lastName] = patient.last_name

    if patient.mobile?
      params[:mobile] = patient.mobile.strip.gsub(/\s+/, '')
    end

    if patient.dob?
      params[:dobString] = patient.dob.try(:strftime, '%Y-%m-%d')
    end
    params
  end
end
