/**
 * Loading indicator for elements
 */
(function($) {
  $.fn.loadingOn = function() {
    var html = '<div class="loading-indicator"><i class="fa fa-spinner fa-spin fa-2x"></i></div>';
    this.addClass('loading');
    this.append(html);
    this.find('.loading-indicator').css({
      opacity: '1',
      position: 'absolute',
      top: '50%',
      left: '50%',
      color: '#44B654'
    });
    this.find('> :not(.loading-indicator)').css('opacity', 0.2);
    return this;
  };

  $.fn.loadingOff = function() {
    this.find('.loading-indicator').remove();
    this.removeClass('loading');
    this.find('> :not(.loading-indicator)').css('opacity', '');
    return this;
  };

  $.fn.toggleLoading = function() {
    if($(this).hasClass('loading')) {
      this.loadingOff();
    } else {
      this.loadingOn();
    }
    return this;
  }
})(jQuery);
