# Create system administrator

admin = AdminUser.create!(
  first_name: 'John',
  last_name: 'Doe',
  email: 'admin@example.com',
  role: AdminUser::SUPER_ADMIN_ROLE,
  password: 'changeme'
)

puts "Admin user created! Email: #{admin.email} / Password: changeme"
