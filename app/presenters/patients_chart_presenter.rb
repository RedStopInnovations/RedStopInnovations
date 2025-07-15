class PatientsChartPresenter
  def results
    [].tap do |results|
      patients = Patient.where 'created_at >= ?', 11.months.ago.beginning_of_month
      groups_by_month =
        patients.pluck(:created_at).group_by do |created_at|
          created_at.beginning_of_month.to_date
        end
      tmp_date = 11.months.ago.beginning_of_month.to_date

      12.times do
        results << {
          date: tmp_date,
          patients_count: groups_by_month[tmp_date].try(:count) || 0
        }
        tmp_date = tmp_date.next_month
      end
    end
  end

  def as_json
    {}.tap do |data|
      data[:labels] = results.map { |e| e[:date].strftime('%b') }

      data[:datasets] = [
        {
          label: 'Appointments',
          backgroundColor: 'rgba(68, 182, 84, 0.35)',
          borderColorColor: 'rgb(68, 182, 84)',
          pointBackgroundColor: 'rgb(68, 182, 84)',
          pointBorderColor: 'rgb(68, 182, 84)',
          data: results.map { |e| e[:patients_count] }
        }
      ]
    end
  end
end
