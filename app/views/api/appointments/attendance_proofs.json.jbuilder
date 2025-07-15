json.attendance_proofs @attendance_proofs do |attendance_proof|
  json.id attendance_proof.id
  json.url url_for(attendance_proof)
  json.file_name attendance_proof.filename
end
