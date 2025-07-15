$(function() {
if ($('#js-page-pricing').length) {
    /* Submit form immediality when a select changed */
    $('#js-form-search select').on('change', function() {
      $('#js-form-search').trigger('submit');
    });

    $('#js-form-search').on('submit', function() {
      // Disable empty inputs to avoid redundant query in url
      $('#js-input-profession, #js-input-location, #js-input-service, #js-input-rate, #js-input-max-price')
      .each(function() {
        if ($(this).val().trim().length === 0) {
          $(this).attr('disabled', 'disabled');
        }
      });
    });
  }
});