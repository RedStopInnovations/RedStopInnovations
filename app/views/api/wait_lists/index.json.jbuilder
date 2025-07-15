json.wait_lists @wait_lists, partial: 'wait_list', as: :wait_list

json.current_page @wait_lists.current_page
json.total_pages @wait_lists.total_pages
json.total_entries @wait_lists.total_count
