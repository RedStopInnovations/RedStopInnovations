module DeletionRecordable
  extend ActiveSupport::Concern

  included do
    has_one :deleted_resource, as: :resource, class_name: 'DeletedResource'

    def delete_by_author(author)
      DeletedResource.create(
        resource: self,
        business: business,
        author: author,
        deleted_at: Time.current,
        associated_patient_id: associated_patient_id
      )
      delete
    end

    def destroy_by_author(author)
      DeletedResource.create(
        business: business,
        resource: self,
        author: author,
        deleted_at: Time.current,
        associated_patient_id: associated_patient_id
      )
      destroy
    end

    def soft_delete(author: nil)
      DeletedResource.create(
        business: business,
        resource: self,
        author: author,
        deleted_at: Time.current
      )
      update(deleted_at: Time.current)
    end

    def associated_patient_id
    end
  end
end
